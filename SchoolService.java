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
    // Public methods
    // -----------------------------------------

    public void showStudents() throws SQLException {

        String query = "begin school_pkg.show_students; end;";

        try (CallableStatement cs = conn.prepareCall(query)) {
            cs.execute();
        }
    }

    public void showStudents() throws SQLException {
        
        String query = "begin ? := school_pkg.get_students; end;";
        
        try (CallableStatement cs = conn.prepareCall(query)) {
            cs.registerOutParameter(1, OracleTypes.CURSOR);
            cs.execute();
            
            try (ResultSet rs = (ResultSet) cs.getObject(1)) {
                // same print loop as getCoursePrerequisites
            }
        }
    }

    public void showStudentsInClass(String classId) throws SQLException {

        String query = "begin school_pkg.show_class_students(?); end;";

        try (CallableStatement cs = conn.prepareCall(query)) {
            cs.setString(1, classId);
            cs.execute();
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

                System.out.println("\n--- PREREQUISITES FOR "
                                   + dept + " " + courseNum + " ---");

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

                if (!foundRows) System.out.println("No prerequisites found.");
            }
        }
    }

    public void enrollGraduate(String bNum, String classId)
            throws SQLException {

        // enroll_graduate is a void procedure: two IN parameters, no OUT.
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
    }

} // End class