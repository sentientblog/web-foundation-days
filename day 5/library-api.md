
# Library Books REST API

Base URL: `/api`

## 1. List All Books

- **Method:** GET
- **Path:** `/api/books`
- **Description:** Returns all books in the library.
- **Success status:** 200 OK

## 2. Get One Book

- **Method:** GET
- **Path:** `/api/books/{id}`
- **Description:** Returns the book with the specified ID.
- **Success status:** 200 OK

## 3. Create a Book

- **Method:** POST
- **Path:** `/api/books`
- **Description:** Creates a new book.
- **Example request body:**

  ```json
  {
    "title": "Things Fall Apart",
    "author": "Chinua Achebe",
    "publishedYear": 1958
  }
  ```

- **Success status:** 201 Created

## 4. Update a Book

- **Method:** PUT
- **Path:** `/api/books/{id}`
- **Description:** Updates an existing book.
- **Example request body:**

  ```json
  {
    "title": "Things Fall Apart",
    "author": "Chinua Achebe",
    "publishedYear": 1958
  }
  ```

- **Success status:** 200 OK

## 5. Delete a Book

- **Method:** DELETE
- **Path:** `/api/books/{id}`
- **Description:** Deletes the book with the specified ID.
- **Success status:** 204 No Content

## 6. List Books by Author

- **Method:** GET
- **Path:** `/api/books?author=Chinua%20Achebe`
- **Description:** Returns books written by the specified author.
- **Success status:** 200 OK

## 7. Search Books by Title

- **Method:** GET
- **Path:** `/api/books?title=Things%20Fall%20Apart`
- **Description:** Returns books matching the specified title.
- **Success status:** 200 OK

## Error Responses

### 400 Bad Request

- **Description:** The request contains invalid data or parameters.
- **Example:** Creating a book without a required title or author.

Example response:

```json
{
  "error": "Title and author are required."
}
```

### 404 Not Found

- **Description:** The requested resource does not exist.
- **Example:** Requesting `GET /api/books/9999` when book ID 9999 does not exist.

Example response:

```json
{
  "error": "Book not found."
}
```
