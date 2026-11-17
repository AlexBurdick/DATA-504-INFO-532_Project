import java.io.BufferedReader;
import java.io.IOException;
import java.sql.*;
import oracle.jdbc.*;
import sql.SqlQueries;

public class SchoolService {

    // Private member variables
    private Connection conn;

    // Constructor
    public SchoolService(Connection conn) {
        this.conn = conn;
    }

    // -----------------------------------------
    // Private methods
    // -----------------------------------------

    private static boolean printResultSet(ResultSet rs)
            throws SQLException {

        ResultSetMetaData meta = rs.getMetaData();
        int columnCount = meta.getColumnCount();
        boolean foundRows = false;

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

    private static boolean printResultSet (ResultSet rs, String header)
            throws SQLException {

        ResultSetMetaData meta = rs.getMetaData();
        int columnCount = meta.getColumnCount();
        boolean foundRows = false;

        while (rs.next()) {

            if (!foundRows && header != null)  System.out.println(header);

            foundRows = true;

            for (int i = 1; i <= columnCount; i++) {
                System.out.print(rs.getObject(i));
                if (i < columnCount)  System.out.print("\t");
            }

            System.out.println();
        }

        return foundRows;
    }
    
    private static void printResultSetWithHeaders(ResultSet rs)
            throws SQLException {

        ResultSetMetaData meta = rs.getMetaData();
        int columnCount = meta.getColumnCount();

        // Print column headers
        for (int i = 1; i <= columnCount; i++) {
            System.out.print(meta.getColumnName(i));
            if (i < columnCount) System.out.print("\t");
        }

        System.out.println();

        // Print rows
        while (rs.next()) {
            for (int i = 1; i <= columnCount; i++) {
                System.out.print(rs.getString(i));
                if (i < columnCount)  System.out.print("\t");
            }

            System.out.println();
        }
    }
    
    private static ResultSet callSQLQuery(Connection conn, String query) 
            throws SQLException {

        CallableStatement cs = conn.prepareCall(query);

        cs.registeredOutParameter(1, OracleTypes.CURSOR);

        cs.execute();

        cs.close();

        return (ResultSet) cs.getObject(1);
    }
    
    // -----------------------------------------
    // Public methods
    // -----------------------------------------

    public void showStudents()
            throws SQLException {

        String query = "begin ? := school_pkg.show_students(); end;";

        ResultSet rs = callSQLQuery(conn, query);

        printResultSetWithHeaders(rs);

        rs.close();
    }

    public void showStudentsInClass(String classId)
            throws SQLException {

        String query = "begin ? := school_pkg.show_class_students(?); end;";

        ResultSet rs = callSQLQuery(conn, query);

        boolean hasStudents = printResultSet(
            rs,
            "\n--- STUDENTS IN CLASS " + classId + " ---"
        );

        // Print message if no students found
        if (!hasStudents) System.out.println("No students found.");

        rs.close();
    }

    public void getCoursePrerequisites(String dept, int courseNum)
            throws SQLException {
        
        String query = "begin ? := school_pkg.show_class_students(?); end;";
        
        ResultSet rs = callSQLQuery(conn, query);
        
        boolean hasPrerequisites = printResultSet(
            rs,
            "\n--- PREREQUISITES FOR " + dept + " " + courseNum + " ---"
        );

        if (!hasPrerequisites) System.out.println("No prerequisites found.");

        rs.close();
    }

    public void enrollGraduate(String bNum, String classId)
            throws SQLException {
        
        String query = "begin school_pkg.enroll_graduate(?, ?); end;";

        ResultSet rs = callSQLQuery(conn, query);

        rs.close();
    }

    public void dropGraduate(String bNum, String classId)
            throws SQLException {
        
        String query = "begin school_pkg.drop_graduate(?, ?); end;";
        
        ResultSet rs = callSQLQuery(conn, query);

        rs.close();
    }

    public void deleteStudent(String bNum)
            throws SQLException {

        String query = "begin school_pkg.delete_student(?); end;";

        ResultSet rs = callSQLQuery(conn, query);

        rs.close();
    }

    public void close() throws SQLException {
        if (conn != null && !conn.isClosed()) {
            conn.close();
        }
    }
    
} // End class