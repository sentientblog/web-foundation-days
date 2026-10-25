
# School Database Design

## Tables

### Students

The `students` table stores each student's ID, name, and email address. The student ID is the primary key, which uniquely identifies each student. The email is also unique, and the name and email cannot be NULL.

### Courses

The `courses` table stores each course's ID, name, and course code. The course ID is the primary key, while the course code is unique so that two courses cannot have the same code.

### Enrolments

The `enrolments` table records which students take which courses and the grade they receive. Its primary key is `enrolment_id`. The `student_id` and `course_id` columns are foreign keys referencing the students and courses tables. A UNIQUE constraint on these two columns prevents a student from enrolling in the same course twice. A grade can be NULL until it is assigned.

## Relationships

There is a one-to-many relationship between students and enrolments because one student can have multiple enrolment records. There is also a one-to-many relationship between courses and enrolments because one course can have multiple students enrolled in it.

Students and courses therefore have a many-to-many relationship: a student can take multiple courses, and a course can contain multiple students. The enrolments table acts as a join table connecting them. It is needed to represent this relationship and store additional information, such as each student's grade for a particular course.

## Index

I would add an index on `enrolments(course_id)` to speed up queries that retrieve students enrolled in a particular course and to help when counting enrolments per course. The UNIQUE constraint on `(student_id, course_id)` already creates an index that can help queries filtering by student ID, so a separate index on `student_id` is not necessary for those queries.

```sql
CREATE INDEX idx_enrolments_course_id
ON enrolments(course_id);
```

## SQL or NoSQL?

I would choose a relational SQL database for this school system. Students, courses, and enrolments have clearly defined relationships, and the system needs foreign keys, unique constraints, and reliable updates to grades. SQL supports these requirements and provides JOINs and aggregate functions for reporting, such as counting students per course. A NoSQL database could work for some school applications, but a relational database such as SQLite is a more natural fit for this structured data and its relationships.
