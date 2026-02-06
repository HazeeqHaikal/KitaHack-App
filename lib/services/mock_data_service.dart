import 'package:due/models/academic_event.dart';
import 'package:due/models/course_info.dart';

/// Mock data service for UI development
/// This simulates what would come from Gemini API in the real system
class MockDataService {
  /// Get sample courses for home screen
  static List<CourseInfo> getSampleCourses() {
    return [
      _getComputerScienceCourse(),
      _getDataStructuresCourse(),
      _getSoftwareEngineeringCourse(),
      _getDatabaseSystemsCourse(),
    ];
  }

  /// Get a specific course by code
  static CourseInfo? getCourseByCode(String code) {
    final courses = getSampleCourses();
    try {
      return courses.firstWhere((c) => c.courseCode == code);
    } catch (e) {
      return null;
    }
  }

  /// Get all upcoming events across all courses
  static List<AcademicEvent> getAllUpcomingEvents() {
    final courses = getSampleCourses();
    final allEvents = <AcademicEvent>[];
    for (var course in courses) {
      allEvents.addAll(course.upcomingEvents);
    }
    allEvents.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return allEvents;
  }

  /// Computer Science Fundamentals Course
  static CourseInfo _getComputerScienceCourse() {
    return CourseInfo(
      courseName: 'Introduction to Computer Science',
      courseCode: 'CS101',
      instructor: 'Dr. Sarah Johnson',
      semester: 'Spring 2026',
      events: [
        AcademicEvent(
          id: 'cs101_1',
          title: 'Assignment 1: Algorithm Analysis',
          dueDate: DateTime(2026, 2, 15, 23, 59),
          description:
              'Analyze time complexity of sorting algorithms. Submit a 5-page report comparing Bubble Sort, Quick Sort, and Merge Sort with code examples.',
          weightage: '15%',
          type: EventType.assignment,
          location: 'Submit via LMS Portal',
        ),
        AcademicEvent(
          id: 'cs101_2',
          title: 'Quiz 1: Programming Fundamentals',
          dueDate: DateTime(2026, 2, 10, 14, 30),
          description:
              'Covers variables, data types, control structures, and functions. 30 minutes, 20 MCQ questions.',
          weightage: '5%',
          type: EventType.quiz,
          location: 'Room B204',
        ),
        AcademicEvent(
          id: 'cs101_3',
          title: 'Midterm Exam',
          dueDate: DateTime(2026, 3, 5, 10, 0),
          description:
              'Comprehensive exam covering Week 1-6 material. Includes programming problems, algorithm design, and theoretical questions.',
          weightage: '25%',
          type: EventType.exam,
          location: 'Engineering Hall - Room 301',
        ),
        AcademicEvent(
          id: 'cs101_4',
          title: 'Lab 2: Recursion & Dynamic Programming',
          dueDate: DateTime(2026, 2, 20, 17, 0),
          description:
              'Implement recursive solutions for Fibonacci, Tower of Hanoi, and a basic dynamic programming problem.',
          weightage: '8%',
          type: EventType.lab,
          location: 'Computer Lab A',
        ),
        AcademicEvent(
          id: 'cs101_5',
          title: 'Group Project: Mini Compiler',
          dueDate: DateTime(2026, 4, 15, 23, 59),
          description:
              'Design and implement a basic lexical analyzer and parser for a simple programming language. Groups of 4.',
          weightage: '20%',
          type: EventType.project,
          location: 'Submit code + documentation',
        ),
        AcademicEvent(
          id: 'cs101_6',
          title: 'Final Project Presentation',
          dueDate: DateTime(2026, 4, 20, 14, 0),
          description:
              'Present your Mini Compiler project. 20-minute presentation followed by 10-minute Q&A. All team members must participate.',
          weightage: '12%',
          type: EventType.presentation,
          location: 'Room A101 - Smart Classroom',
        ),
        AcademicEvent(
          id: 'cs101_7',
          title: 'Final Examination',
          dueDate: DateTime(2026, 5, 8, 9, 0),
          description:
              'Cumulative final exam covering all course material. 3-hour exam with programming, design, and theoretical sections.',
          weightage: '35%',
          type: EventType.exam,
          location: 'Main Exam Hall C',
        ),
      ],
    );
  }

  /// Data Structures & Algorithms Course
  static CourseInfo _getDataStructuresCourse() {
    return CourseInfo(
      courseName: 'Data Structures & Algorithms',
      courseCode: 'CS201',
      instructor: 'Prof. Michael Chen',
      semester: 'Spring 2026',
      events: [
        AcademicEvent(
          id: 'cs201_1',
          title: 'Assignment 1: Linked Lists Implementation',
          dueDate: DateTime(2026, 2, 8, 23, 59),
          description:
              'Implement singly and doubly linked lists with all basic operations (insert, delete, search, reverse).',
          weightage: '10%',
          type: EventType.assignment,
          location: 'GitHub Classroom',
        ),
        AcademicEvent(
          id: 'cs201_2',
          title: 'Quiz 1: Big-O Notation',
          dueDate: DateTime(2026, 2, 6, 15, 0),
          description:
              'Test on time and space complexity analysis. Calculate Big-O for various code snippets.',
          weightage: '5%',
          type: EventType.quiz,
          location: 'Online (Canvas)',
        ),
        AcademicEvent(
          id: 'cs201_3',
          title: 'Assignment 2: Binary Search Trees',
          dueDate: DateTime(2026, 2, 25, 23, 59),
          description:
              'Build a BST with insertion, deletion, traversal methods. Include AVL tree balancing as bonus.',
          weightage: '15%',
          type: EventType.assignment,
          location: 'GitHub Classroom',
        ),
        AcademicEvent(
          id: 'cs201_4',
          title: 'Lab Practical: Hash Tables',
          dueDate: DateTime(2026, 3, 1, 17, 0),
          description:
              'Implement hash table with collision resolution using chaining and linear probing.',
          weightage: '8%',
          type: EventType.lab,
          location: 'Lab 3B',
        ),
        AcademicEvent(
          id: 'cs201_5',
          title: 'Midterm Exam',
          dueDate: DateTime(2026, 3, 12, 10, 0),
          description:
              'Arrays, linked lists, stacks, queues, trees, and basic graph concepts. Mix of coding and theory.',
          weightage: '30%',
          type: EventType.exam,
          location: 'Room B305',
        ),
        AcademicEvent(
          id: 'cs201_6',
          title: 'Assignment 3: Graph Algorithms',
          dueDate: DateTime(2026, 4, 5, 23, 59),
          description:
              'Implement BFS, DFS, Dijkstra\'s shortest path, and Kruskal\'s MST algorithm.',
          weightage: '18%',
          type: EventType.assignment,
          location: 'GitHub Classroom',
        ),
        AcademicEvent(
          id: 'cs201_7',
          title: 'Final Project: Algorithm Visualizer',
          dueDate: DateTime(2026, 5, 1, 23, 59),
          description:
              'Create an interactive web app that visualizes sorting and pathfinding algorithms.',
          weightage: '22%',
          type: EventType.project,
          location: 'Deploy on Netlify/Vercel',
        ),
        AcademicEvent(
          id: 'cs201_8',
          title: 'Final Exam',
          dueDate: DateTime(2026, 5, 15, 14, 0),
          description:
              'Comprehensive final covering all data structures and algorithms taught. Emphasis on graph algorithms.',
          weightage: '32%',
          type: EventType.exam,
          location: 'Exam Hall A',
        ),
      ],
    );
  }

  /// Software Engineering Course
  static CourseInfo _getSoftwareEngineeringCourse() {
    return CourseInfo(
      courseName: 'Software Engineering Principles',
      courseCode: 'SE301',
      instructor: 'Dr. Emily Rodriguez',
      semester: 'Spring 2026',
      events: [
        AcademicEvent(
          id: 'se301_1',
          title: 'Assignment 1: Requirements Document',
          dueDate: DateTime(2026, 2, 12, 23, 59),
          description:
              'Create a comprehensive Software Requirements Specification (SRS) document for a mobile app idea.',
          weightage: '12%',
          type: EventType.assignment,
          location: 'Submit PDF on LMS',
        ),
        AcademicEvent(
          id: 'se301_2',
          title: 'Quiz 1: SDLC Models',
          dueDate: DateTime(2026, 2, 14, 11, 0),
          description:
              'Test on Waterfall, Agile, Scrum, and DevOps methodologies. Case study analysis included.',
          weightage: '6%',
          type: EventType.quiz,
          location: 'Room C202',
        ),
        AcademicEvent(
          id: 'se301_3',
          title: 'Team Project Sprint 1 Demo',
          dueDate: DateTime(2026, 3, 3, 16, 0),
          description:
              'Present first sprint deliverables: user stories, wireframes, and initial prototype. 15-min demo per team.',
          weightage: '10%',
          type: EventType.presentation,
          location: 'Innovation Lab',
        ),
        AcademicEvent(
          id: 'se301_4',
          title: 'Assignment 2: UML Diagrams',
          dueDate: DateTime(2026, 3, 18, 23, 59),
          description:
              'Create use case, class, sequence, and activity diagrams for your project using draw.io or Lucidchart.',
          weightage: '14%',
          type: EventType.assignment,
          location: 'Upload to LMS',
        ),
        AcademicEvent(
          id: 'se301_5',
          title: 'Midterm Exam',
          dueDate: DateTime(2026, 3, 20, 13, 0),
          description:
              'Requirements engineering, design patterns, UML, testing strategies, and Agile principles.',
          weightage: '25%',
          type: EventType.exam,
          location: 'Room D401',
        ),
        AcademicEvent(
          id: 'se301_6',
          title: 'Lab: Unit Testing Workshop',
          dueDate: DateTime(2026, 4, 8, 17, 0),
          description:
              'Hands-on practice with JUnit/pytest. Write unit tests achieving >80% code coverage.',
          weightage: '8%',
          type: EventType.lab,
          location: 'Computer Lab D',
        ),
        AcademicEvent(
          id: 'se301_7',
          title: 'Team Project Sprint 2 Demo',
          dueDate: DateTime(2026, 4, 14, 16, 0),
          description:
              'Demo working features from Sprint 2. Must include integration with backend API.',
          weightage: '12%',
          type: EventType.presentation,
          location: 'Innovation Lab',
        ),
        AcademicEvent(
          id: 'se301_8',
          title: 'Final Project Submission',
          dueDate: DateTime(2026, 5, 5, 23, 59),
          description:
              'Complete software system with documentation: code, test reports, deployment guide, and user manual.',
          weightage: '25%',
          type: EventType.project,
          location: 'GitHub + LMS',
        ),
        AcademicEvent(
          id: 'se301_9',
          title: 'Final Project Presentation',
          dueDate: DateTime(2026, 5, 10, 9, 0),
          description:
              'Professional pitch of your software project to a panel. 25-minute presentation + demo.',
          weightage: '13%',
          type: EventType.presentation,
          location: 'Auditorium B',
        ),
      ],
    );
  }

  /// Database Systems Course
  static CourseInfo _getDatabaseSystemsCourse() {
    return CourseInfo(
      courseName: 'Database Management Systems',
      courseCode: 'DB202',
      instructor: 'Prof. David Kim',
      semester: 'Spring 2026',
      events: [
        AcademicEvent(
          id: 'db202_1',
          title: 'Assignment 1: ER Diagram Design',
          dueDate: DateTime(2026, 2, 18, 23, 59),
          description:
              'Design an Entity-Relationship diagram for a university management system with proper normalization.',
          weightage: '12%',
          type: EventType.assignment,
          location: 'Submit via LMS',
        ),
        AcademicEvent(
          id: 'db202_2',
          title: 'Quiz 1: SQL Basics',
          dueDate: DateTime(2026, 2, 22, 10, 30),
          description:
              'SELECT, JOIN, GROUP BY, aggregate functions. Write SQL queries for given scenarios.',
          weightage: '7%',
          type: EventType.quiz,
          location: 'Online Quiz (1 hour)',
        ),
        AcademicEvent(
          id: 'db202_3',
          title: 'Lab 1: PostgreSQL Setup & Queries',
          dueDate: DateTime(2026, 2, 27, 17, 0),
          description:
              'Install PostgreSQL, create database, populate tables, and execute 20 practice queries.',
          weightage: '8%',
          type: EventType.lab,
          location: 'Database Lab',
        ),
        AcademicEvent(
          id: 'db202_4',
          title: 'Assignment 2: Normalization & Indexing',
          dueDate: DateTime(2026, 3, 15, 23, 59),
          description:
              'Normalize a denormalized schema to 3NF. Design appropriate indexes and explain performance impact.',
          weightage: '15%',
          type: EventType.assignment,
          location: 'PDF submission',
        ),
        AcademicEvent(
          id: 'db202_5',
          title: 'Midterm Practical Exam',
          dueDate: DateTime(2026, 3, 25, 14, 0),
          description:
              'Computer-based practical exam. Design schema, write complex SQL queries, and optimize performance.',
          weightage: '28%',
          type: EventType.exam,
          location: 'Database Lab (2 hours)',
        ),
        AcademicEvent(
          id: 'db202_6',
          title: 'Assignment 3: Stored Procedures & Triggers',
          dueDate: DateTime(2026, 4, 10, 23, 59),
          description:
              'Write PL/pgSQL stored procedures and triggers for inventory management system.',
          weightage: '13%',
          type: EventType.assignment,
          location: 'GitHub submission',
        ),
        AcademicEvent(
          id: 'db202_7',
          title: 'Group Project: Database Application',
          dueDate: DateTime(2026, 4, 28, 23, 59),
          description:
              'Build a full-stack web app with CRUD operations, transactions, and analytics dashboard. Teams of 3.',
          weightage: '20%',
          type: EventType.project,
          location: 'Live demo + code',
        ),
        AcademicEvent(
          id: 'db202_8',
          title: 'Project Presentation',
          dueDate: DateTime(2026, 5, 3, 13, 0),
          description:
              'Present database schema, optimization techniques used, and demo key features of your application.',
          weightage: '10%',
          type: EventType.presentation,
          location: 'Room B201',
        ),
        AcademicEvent(
          id: 'db202_9',
          title: 'Final Exam',
          dueDate: DateTime(2026, 5, 18, 10, 0),
          description:
              'Comprehensive exam on all topics: design, SQL, transactions, concurrency, recovery, and NoSQL concepts.',
          weightage: '32%',
          type: EventType.exam,
          location: 'Main Exam Hall D',
        ),
      ],
    );
  }

  /// Get statistics across all courses
  static Map<String, dynamic> getOverallStats() {
    final courses = getSampleCourses();
    final allEvents = getAllUpcomingEvents();
    final upcomingThisWeek = allEvents
        .where((e) => e.daysUntilDue <= 7 && e.daysUntilDue >= 0)
        .length;
    final highPriorityCount = allEvents
        .where((e) => e.priority == EventPriority.high)
        .length;

    return {
      'totalCourses': courses.length,
      'totalEvents': allEvents.length,
      'upcomingThisWeek': upcomingThisWeek,
      'highPriorityEvents': highPriorityCount,
      'assignmentsCount': allEvents
          .where((e) => e.type == EventType.assignment)
          .length,
      'examsCount': allEvents.where((e) => e.type == EventType.exam).length,
      'projectsCount': allEvents
          .where((e) => e.type == EventType.project)
          .length,
    };
  }
}
