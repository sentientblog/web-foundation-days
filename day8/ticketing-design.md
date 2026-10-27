# TicketHub: System Design

## Part 1: Requirements

### Functional requirements

TicketHub must allow users to:

1. Register, sign in, and manage their accounts.
2. Browse, search, and view concerts and other events.
3. View available seats and their prices.
4. Temporarily hold an available seat while completing checkout.
5. Pay for an order and receive a booking confirmation.
6. View their purchased tickets and order history.
7. Release expired or cancelled reservations so that seats can be sold again.

### Non-functional requirements

- **Performance:** Event pages should load within two seconds under normal conditions, and seat availability and checkout requests should respond quickly during a sale.
- **Correctness:** A seat must never be sold to two different orders. Payment and booking states must remain consistent.
- **Fairness:** Users should be admitted to a high-demand sale through a fair queue rather than allowing a few users to overwhelm the service by sending repeated requests.
- **Availability:** The system should remain usable during server failures and traffic spikes, or communicate clearly when a user must wait.
- **Scalability:** Application servers and background workers should be able to scale as demand increases.
- **Security:** Users must only access their own orders and tickets. Payment information must be handled securely by a trusted payment provider.
- **Reliability:** Failed or repeated payment requests must not create duplicate orders or charge users multiple times.
- **Maintainability:** The system should use clear APIs, logging, monitoring, and automated tests to make problems easier to detect and fix.

## Part 2: Traffic and Capacity Estimates

### Assumptions

- TicketHub has 2,000,000 registered users.
- On a normal day, 50,000 people visit the website.
- Each normal-day visitor views 10 pages.
- A normal day produces 5,000 ticket sales.
- During a popular concert sale, 200,000 people try to buy tickets for 20,000 available seats in the first 10 minutes.
- A day contains 86,400 seconds, and 10 minutes contains 600 seconds.
- Page views and ticket sales are averaged over the full day for the normal-day estimates. Real traffic is not evenly distributed.
- The big-sale calculation uses the average arrival rate during the ten-minute window, not the potentially higher instantaneous peak.

### Normal-day traffic

**Page views per day**

50,000 visitors × 10 pages = 500,000 page views per day.

**Average page views per second**

500,000 ÷ 86,400 ≈ 5.79 page views per second.

**Average ticket sales per second**

5,000 ÷ 86,400 ≈ 0.058 ticket sales per second, or about 208 sales per hour on average.

The actual sales rate will vary depending on event popularity and time of day.

### Popular concert sale

**Average purchase attempts per second**

200,000 ÷ 600 ≈ 333.33 purchase attempts per second.

**Average seats available per second if all seats are sold evenly**

20,000 ÷ 600 ≈ 33.33 seats per second.

**Demand compared with supply**

200,000 people ÷ 20,000 seats = 10 potential buyers per seat.

Only 10% of the people attempting to buy can receive one of the 20,000 seats if each person purchases one seat and all seats are sold.

### Comparison and design implications

The normal-day average is approximately 5.79 page views per second, while the popular sale receives an average of 333.33 purchase attempts per second. These figures measure different operations, so they should not be treated as identical workloads. Nevertheless, the sale creates a sudden concentration of expensive, correctness-sensitive requests.

TicketHub should use a virtual waiting room, rate limiting, scalable application servers, caching for event information, and a strongly consistent database for seat reservations. Cached information can help users browse events, but the final seat allocation must be decided by the authoritative database.

## Part 3: API Design

The API uses the base path `/api/v1`. Requests and responses use JSON unless otherwise stated.

| Method and endpoint | Purpose | Important responses |
|---|---|---|
| `GET /api/v1/events` | List and search events | `200 OK` |
| `GET /api/v1/events/{eventId}` | View event details | `200 OK`, `404 Not Found` |
| `GET /api/v1/events/{eventId}/seats` | View seat availability and prices | `200 OK` |
| `POST /api/v1/seat-holds` | Temporarily hold an available seat | `201 Created`, `409 Conflict` |
| `DELETE /api/v1/seat-holds/{holdId}` | Release a user's active hold | `204 No Content`, `404 Not Found` |
| `POST /api/v1/orders` | Create an order from a valid seat hold | `201 Created`, `409 Conflict` |
| `POST /api/v1/orders/{orderId}/payment` | Initiate or confirm payment through a payment provider | `200 OK`, `402 Payment Required` |
| `GET /api/v1/me/tickets` | List the signed-in user's tickets | `200 OK`, `401 Unauthorized` |

### Example: Browsing events

Request:

```http
GET /api/v1/events
```

Example response:

```json
{
  "events": [
    {
      "id": 42,
      "name": "Summer Live",
      "venue": "City Arena",
      "startsAt": "2027-06-12T18:00:00Z"
    }
  ]
}
```

### Example: Holding a seat

Request:

```http
POST /api/v1/seat-holds
Content-Type: application/json
```

```json
{
  "eventId": 42,
  "seatId": 105
}
```

Example successful response:

```json
{
  "holdId": 901,
  "eventId": 42,
  "seatId": 105,
  "status": "held",
  "expiresAt": "2027-06-12T17:05:00Z"
}
```

If another user already holds or has purchased the seat, the API returns `409 Conflict` rather than creating another hold.

### Example: Error response

```json
{
  "error": {
    "code": "SEAT_UNAVAILABLE",
    "message": "This seat is no longer available."
  }
}
```

The API should require authentication for holding seats, ordering, payment, and ticket retrieval. Payment requests should use idempotency keys so that retrying the same request does not create duplicate charges or orders.

## Part 4: Data Model

TicketHub uses a relational database because ticket sales require transactions, relationships, and strict uniqueness constraints.

### Tables and relationships

#### 1. Users

| Column | Type | Rules |
|---|---|---|
| `id` | BIGINT | Primary key |
| `email` | VARCHAR(255) | Required, unique |
| `password_hash` | VARCHAR(255) | Required |
| `created_at` | TIMESTAMP | Required |

Each user can place many orders.

#### 2. Events

| Column | Type | Rules |
|---|---|---|
| `id` | BIGINT | Primary key |
| `name` | VARCHAR(255) | Required |
| `venue` | VARCHAR(255) | Required |
| `starts_at` | TIMESTAMP | Required |
| `status` | VARCHAR(30) | Required |

Each event has many seats and many orders.

#### 3. Seats

| Column | Type | Rules |
|---|---|---|
| `id` | BIGINT | Primary key |
| `event_id` | BIGINT | Foreign key to Events |
| `seat_number` | VARCHAR(30) | Required |
| `price` | DECIMAL(10,2) | Required |
| `status` | VARCHAR(20) | Required |
| `hold_user_id` | BIGINT | Nullable foreign key to Users |
| `hold_expires_at` | TIMESTAMP | Nullable |

The combination of `event_id` and `seat_number` must be unique, preventing duplicate records for the same physical seat at an event. A seat's status can be `available`, `held`, or `sold`.

#### 4. Orders

| Column | Type | Rules |
|---|---|---|
| `id` | BIGINT | Primary key |
| `user_id` | BIGINT | Foreign key to Users |
| `seat_id` | BIGINT | Foreign key to Seats, unique |
| `amount` | DECIMAL(10,2) | Required |
| `status` | VARCHAR(20) | Required |
| `idempotency_key` | VARCHAR(100) | Required, unique |
| `created_at` | TIMESTAMP | Required |

Each order belongs to one user and one seat in this simplified model. The unique `seat_id` constraint prevents a second order from being created for a seat already associated with another order. Cancelled orders must follow a controlled process before a seat can be sold again.

#### 5. SeatHolds

| Column | Type | Rules |
|---|---|---|
| `id` | BIGINT | Primary key |
| `user_id` | BIGINT | Foreign key to Users |
| `seat_id` | BIGINT | Foreign key to Seats |
| `expires_at` | TIMESTAMP | Required |
| `status` | VARCHAR(20) | Required |

A user can create holds, and each hold refers to a seat. Only one active hold may exist for a given seat at a time. This must be enforced using a transaction and a suitable database constraint or locking strategy, not merely by checking availability in application code.

### Relationships

- Users → Orders: one-to-many.
- Events → Seats: one-to-many.
- Users → SeatHolds: one-to-many.
- Seats → SeatHolds: one-to-many over time, allowing expired or released hold history.
- Seats → Orders: one-to-one in this simplified design, enforced by a unique `seat_id`.

### Preventing two people from buying the same seat

The database, rather than the user interface or cache, is the final authority on seat ownership.

1. When a user requests a seat, the application begins a database transaction.
2. It locks the relevant seat row, or performs an atomic conditional update that only succeeds if the seat is available or its previous hold has expired.
3. If successful, the application changes the seat to `held`, records the user and hold expiration, and commits the transaction.
4. A competing request for the same seat must wait or fail the conditional update. It cannot create a second active hold.
5. During checkout, the application verifies that the hold belongs to the user and has not expired.
6. After payment is confirmed, the application uses another transaction to mark the seat as `sold` and the order as `paid`, subject to uniqueness and state checks.
7. If the hold expires or payment fails, the seat can be released safely. A delayed payment confirmation must not sell a seat that has already been allocated to another buyer; it must be reconciled or refunded.

A transaction makes related database changes succeed or fail together. Row-level locking or conditional updates prevent simultaneous requests from both claiming the same seat, while unique constraints provide an additional layer of protection. Payment-provider callbacks should be authenticated and processed idempotently.

## Part 5: Architecture

### Architecture diagram

```text
                      +------------------+
                      |       Users      |
                      +--------+---------+
                               |
                               v
                      +------------------+
                      |       DNS        |
                      +--------+---------+
                               |
                               v
                      +------------------+
                      |   CDN / Cache    |
                      | Static event data|
                      +--------+---------+
                               |
                               v
                      +------------------+
                      | Virtual Waiting  |
                      | Room / Rate Limit|
                      +--------+---------+
                               |
                               v
                      +------------------+
                      |  Load Balancer   |
                      +--------+---------+
                               |
                  +------------+------------+
                  |                         |
                  v                         v
           +--------------+          +--------------+
           | App Server 1 |          | App Server 2 |
           +------+-------+          +------+-------+
                  |                         |
                  +------------+------------+
                               |
                     +---------+---------+
                     |                   |
                     v                   v
              +-------------+     +-------------+
              | Cache       |     | Primary DB  |
              | Event data  |     | Seat holds, |
              +-------------+     | orders      |
                                  +------+------+
                                         |
                                         v
                                  +-------------+
                                  | Read Replica|
                                  | Browsing    |
                                  +-------------+

           +----------------+       +------------------+
           | Payment        |<----->| Payment Provider |
           | Integration    |       +------------------+
           +--------+-------+
                    |
                    v
           +----------------+
           | Message Queue  |
           +--------+-------+
                    |
                    v
           +----------------+
           | Background     |
           | Workers        |
           +----------------+

           +----------------+
           | Monitoring,    |
           | Logs, Alerts   |
           +----------------+
```

### Component explanations

- **DNS:** Directs users to TicketHub's public service endpoint.
- **CDN:** Serves static assets and cacheable event images close to users, reducing origin traffic.
- **Virtual waiting room:** Admits users in a controlled order during popular sales so the application and database are not overwhelmed.
- **Rate limiter:** Restricts excessive requests from a user or client to reduce abuse and protect service capacity.
- **Load balancer:** Distributes incoming requests across healthy application servers.
- **Application servers:** Validate requests, authenticate users, apply business rules, and coordinate seat holds, orders, and payment integration.
- **Cache:** Stores frequently accessed event information to reduce repeated database reads; it is never authoritative for seat ownership.
- **Primary database:** Enforces transactions and constraints for seat availability, holds, and orders.
- **Read replica:** Handles suitable browsing queries so that the primary database can focus on correctness-sensitive writes.
- **Payment integration:** Communicates securely with the payment provider and processes payment confirmations without trusting client-side claims.
- **Message queue:** Buffers asynchronous work, such as sending confirmations, so temporary spikes do not overwhelm background services.
- **Background workers:** Process queued jobs such as email delivery, expired-hold cleanup, and payment reconciliation.
- **Monitoring and alerts:** Track latency, error rates, queue depth, database contention, payment failures, and available capacity.

### How the architecture survives a big sale

The waiting room limits how many users enter the checkout path at once, while event pages and other cacheable data can be served without querying the primary database on every request. Multiple application servers can scale horizontally, and the load balancer can route around unhealthy instances.

The primary database remains the single logical authority for seat allocation, with row locks or atomic updates and constraints preventing double-booking. A read replica supports browsing but must not be used to make the final decision about whether a seat is available because replication can lag. The system should also use database connection limits, bounded queues, timeouts, retries with backoff, and monitoring to prevent overload from cascading through the service.

For availability, the database should have a tested failover strategy, and critical services should run redundantly where possible. A waiting room can slow admission when the system is at capacity instead of allowing uncontrolled traffic to cause failures.

## Part 6: Trade-Offs

### 1. Fairness versus speed

A virtual waiting room smooths traffic and gives users a more orderly sale experience. However, users may wait longer before they can browse or purchase tickets. TicketHub should communicate queue status clearly and avoid claiming that the queue guarantees a seat.

### 2. Strong consistency versus read performance

Using the primary database for seat allocation and transactional checkout protects correctness. However, row locks and concurrent writes can reduce throughput when thousands of users compete for a small set of seats. Read replicas and caches improve browsing performance, but they cannot safely decide who owns a seat.

### 3. Temporary holds versus ticket availability

A short seat hold gives users time to complete payment and reduces checkout conflicts. However, users may abandon checkout and temporarily block seats. Expiration, cleanup, and carefully designed payment confirmation logic are required to release seats without accidentally selling the same seat twice.

### 4. Scaling capacity versus operating cost

More application servers, database capacity, and redundant infrastructure can handle surges and reduce downtime. However, this costs more and adds operational complexity. Autoscaling and a waiting room help balance capacity against cost, but autoscaling alone cannot instantly create unlimited database write capacity.

## Conclusion

TicketHub must handle normal browsing efficiently and survive a concentrated sale where 200,000 people compete for 20,000 seats. Caching, read replicas, a waiting room, load balancing, and horizontally scalable application servers help manage traffic. Most importantly, database transactions, atomic seat-state changes, and unique constraints ensure that no seat is sold to two buyers. Correctness and fairness take priority over allowing every request to proceed immediately.
