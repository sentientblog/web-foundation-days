
PRAGMA foreign_keys = ON;

-- Start with a clean database so the script can be rerun.
DROP TABLE IF EXISTS enrolments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;

-- 1. Create the students table.
CREATE TABLE students (
    student_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE
);

-- 2. Create the courses table.
CREATE TABLE courses (
    course_id INTEGER PRIMARY KEY,
    course_name TEXT NOT NULL,
    course_code TEXT NOT NULL UNIQUE
);

-- 3. Create the enrolments table.
-- This connects students to courses and stores their grades.
CREATE TABLE enrolments (
    enrolment_id INTEGER PRIMARY KEY,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    grade TEXT,

    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id),

    UNIQUE (student_id, course_id)
);

-- Insert at least 3 students.
INSERT INTO students (student_id, name, email) VALUES
    (1, 'Amina Hassan', 'amina@example.com'),
    (2, 'Brian Otieno', 'brian@example.com'),
    (3, 'Carol Wanjiku', 'carol@example.com'),
    (4, 'David Kamau', 'david@example.com');

-- Insert at least 3 courses.
INSERT INTO courses (course_id, course_name, course_code) VALUES
    (1, 'Database Systems', 'DB101'),
    (2, 'Web Development', 'WEB101'),
    (3, 'Computer Networks', 'NET101');

-- Insert at least 5 enrolments.
INSERT INTO enrolments
    (enrolment_id, student_id, course_id, grade)
VALUES
    (1, 1, 1, 'A'),
    (2, 1, 2, 'B'),
    (3, 2, 1, 'B'),
    (4, 2, 3, 'A'),
    (5, 3, 2, 'A');

-- QUERY 1: All courses taken by one student, identified by name.
SELECT
    s.name AS student_name,
    c.course_name,
    e.grade
FROM students AS s
JOIN enrolments AS e ON s.student_id = e.student_id
JOIN courses AS c ON e.course_id = c.course_id
WHERE s.name = 'Amina Hassan';

-- QUERY 2: All students enrolled on one course.
SELECT
    s.name AS student_name,
    c.course_name,
    e.grade
FROM students AS s
JOIN enrolments AS e ON s.student_id = e.student_id
JOIN courses AS c ON e.course_id = c.course_id
WHERE c.course_name = 'Database Systems';

-- QUERY 3: Number of students enrolled in each course,
-- including courses with zero enrolments.
SELECT
    c.course_name,
    COUNT(e.student_id) AS student_count
FROM courses AS c
LEFT JOIN enrolments AS e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name;

-- QUERY 4: Students who have no enrolments.
SELECT
    s.student_id,
    s.name,
    s.email
FROM students AS s
LEFT JOIN enrolments AS e ON s.student_id = e.student_id
WHERE e.enrolment_id IS NULL;

-- QUERY 5: Update one enrolment's grade.
UPDATE enrolments
SET grade = 'A'
WHERE enrolment_id = 3;

-- Verify the updated grade.
SELECT *
FROM enrolments
WHERE enrolment_id = 3;
