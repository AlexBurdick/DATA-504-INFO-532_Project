import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import oracle.jdbc.OracleTypes;

public class SchoolService {

    // Private member variables
    private Connection conn;

    // Constructor
    public SchoolService(Connection conn) {
        this.conn = conn;
    }

    // -----------------------------------------
    // Private helpers
    // -----------------------------------------

    // Print any ResultSet, however many columns it has, with a header row.
    // Returns true if at least one row was printed.
    private static boolean printResultSet(ResultSet rs, String header)
            throws SQLException {

        ResultSetMetaData meta = rs.getMetaData();
        int columnCount = meta.getColumnCount();
        boolean foundRows = false;

        if (header != null) System.out.println(header);

        // column headers
        for (int i = 1; i <= columnCount; i++) {
            System.out.print(meta.getColumnName(i));
            if (i < columnCount) System.out.print("\t");
        }
        System.out.println();

        // rows
        while (rs.next()) {
            foundRows = true;
            for (int i = 1; i <= columnCount; i++) {
                System.out.print(rs.getString(i));
                if (i < columnCount) System.out.print("\t");
            }
            System.out.println();
        }

        return foundRows;
    }

    // Call a zero-argument function that returns a ref cursor, print it.
    private void showAll(String functionName, String header)
            throws SQLException {

        String query = "begin ? := school_pkg." + functionName + "; end;";

        try (CallableStatement cs = conn.prepareCall(query)) {
            cs.registerOutParameter(1, OracleTypes.CURSOR);
            cs.execute();

            try (ResultSet rs = (ResultSet) cs.getObject(1)) {
                boolean found = printResultSet(rs, header);
                if (!found) System.out.println("No rows found.");
            }
        }
    }

    // -----------------------------------------
    // Public methods
    // -----------------------------------------

    public void showStudents() throws SQLException {
        showAll("show_students", "\n--- STUDENTS ---");
    }

    public void showCourses() throws SQLException {
        showAll("show_courses", "\n--- COURSES ---");
    }

    public void showCourseCredit() throws SQLException {
        showAll("show_course_credit", "\n--- COURSE CREDIT ---");
    }

    public void showClasses() throws SQLException {
        showAll("show_classes", "\n--- CLASSES ---");
    }

    public void showGEnrollments() throws SQLException {
        showAll("show_g_enrollments", "\n--- G_ENROLLMENTS ---");
    }

    public void showScoreGrade() throws SQLException {
        showAll("show_score_grade", "\n--- SCORE_GRADE ---");
    }

    public void showPrerequisites() throws SQLException {
        showAll("show_prerequisites", "\n--- PREREQUISITES ---");
    }

    public void showLogs() throws SQLException {
        showAll("show_logs", "\n--- LOGS ---");
    }

    public void showTableNames() throws SQLException {
        showAll("get_table_names", "\n--- TABLES ---");
    }

    public void showStudentsInClass(String classId) throws SQLException {

        String query = "begin ? := school_pkg.show_class_students(?); end;";

        try (CallableStatement cs = conn.prepareCall(query)) {
            cs.registerOutParameter(1, OracleTypes.CURSOR);
            cs.setString(2, classId);
            cs.execute();

            try (ResultSet rs = (ResultSet) cs.getObject(1)) {
                boolean found = printResultSet(
                    rs, "\n--- STUDENTS IN CLASS " + classId + " ---");
                if (!found) System.out.println("No students found.");
            }
        }
    }

    public void getCoursePrerequisites(String dept, int courseNum)
            throws SQLException {

        String query = "begin school_pkg.get_all_prerequisites(?, ?, ?); end;";

        try (CallableStatement cs = conn.prepareCall(query)) {
            cs.setString(1, dept);
            cs.setInt(2, courseNum);
            cs.registerOutParameter(3, OracleTypes.CURSOR);
            cs.execute();

            try (ResultSet rs = (ResultSet) cs.getObject(3)) {
                boolean found = printResultSet(
                    rs, "\n--- PREREQUISITES FOR " + dept + " " + courseNum + " ---");
                if (!found) System.out.println("No prerequisites found.");
            }
        }
    }

    public void enrollGraduate(String bNum, String classId)
            throws SQLException {

        String query = "begin school_pkg.enroll_graduate(?, ?); end;";

        try (CallableStatement cs = conn.prepareCall(query)) {
            cs.setString(1, bNum);
            cs.setString(2, classId);
            cs.execute();
        }
    }

    public void dropGraduate(String bNum, String classId)
            throws SQLException {

        String query = "begin school_pkg.drop_graduate(?, ?); end;";

        try (CallableStatement cs = conn.prepareCall(query)) {
            cs.setString(1, bNum);
            cs.setString(2, classId);
            cs.execute();
        }
    }

    public void deleteStudent(String bNum) throws SQLException {

        String query = "begin school_pkg.delete_student(?); end;";

        try (CallableStatement cs = conn.prepareCall(query)) {
            cs.setString(1, bNum);
            cs.execute();
        }
    }

    public void close() throws SQLException {
        if (conn != null && !conn.isClosed()) {
            conn.close();
        }
        
        System.out.println("Database connection closed.");
    }

} // End class