import java.sql.*;
import oracle.jdbc.*;
import java.math.*;
import java.io.*;
import java.awt.*;
import oracle.jdbc.pool.OracleDataSource;

public class Project {
   public static void main (String args []) throws SQLException {
      
      // Variable declarations
      String bnum;
      String classid;
      String dept;
      int courseNum;
      int choice;
      
      // Keyboard input setup from mydemo1 and mydemo2
      BufferedReader readKeyBoard = new BufferedReader(
         new InputStreamReader(System.in)
      );
      
      // -----------------------------------------
      // ESTABLISH CONNECTION WIHT ORACLE DB
      // -----------------------------------------
      Connection conn = null;

      // Loop until connection is made (credentials are accepted)
      while (conn == null) {
         try {
            // Prompt user for db credentials
            String username = prompt(readKeyBoard, "Username: ");
            String password = prompt(readKeyBoard, "Password: ");

            // Database connection setup from mydemo1 through mydemo4
            OracleDataSource ds = new oracle.jdbc.pool.OracleDataSource();
            ds.setURL("jdbc:oracle:thin:@castor.cc.binghamton.edu:1521:ACAD111");

            conn = ds.getConnection(username, password);
            System.out.println("Connected successfully.\n");
            
         } catch (SQLException e) {
            System.out.println("Login failed: " + e.getMessage());
            System.out.println("Please try again.\n");
         }
      }

      // Instantiate SchoolService
      SchoolService school = new SchoolService(conn);

      // CLI MENU
      // Java do-while loop and switch-case control flow for menu interaction (https://docs.oracle.com/javase/tutorial/java/nutsandbolts/while.html)
      do
      {
         // Printing a Java console menu structure
         printMenu();

         String inputStr = readKeyBoard.readLine();                     // Get user input
         if (inputStr == null || inputStr.trim().isEmpty())  continue;  // Check if the user's input is null
         choice = Integer.parseInt(inputStr.trim());                    // Convert validated input into integer

         try
         {
            switch (choice)
            {
               case 1:
                  school.showStudents();
                  break;

               case 2:
                  classid = prompt(readKeyBoard, "Enter Class ID: ");
                  school.showStudentsInClass(classid);
                  break;

               case 3:
                  dept = prompt(readKeyBoard, "Enter Department: ");
                  courseNum = Integer.parseInt(prompt(readKeyBoard, "Enter Course Number: "));
                  school.getCoursePrerequisites(dept, courseNum);
                  break;

               case 4:
                  // Stored procedure execution syntax from mydemo2
                  bnum = prompt(readKeyBoard, "Enter Student B#: ");
                  classid = prompt(readKeyBoard, "Enter Class ID: ");
                  school.enrollGraduate(bnum, classid);
                  break;

               case 5: // Drop graduate student
                  bnum = prompt(readKeyBoard, "Enter Student B#: ");
                  classid = prompt(readKeyBoard, "Enter Class ID to drop: ");
                  school.dropGraduate(bnum, classid);
                  break;

               case 6: // Delete student
                  bnum = prompt(readKeyBoard, "Enter Student B# to delete: ");
                  school.deleteStudent(bnum);
                  break;

               case 7:
                  System.out.println("Exiting application. Goodbye!");
                  break;

               default:
                  System.out.println("Invalid choice. Please select a number between 1 and 7.");
            }
         }
         // Exceptions inside the loop so it continues even if something is entered in wrong
         catch (SQLException ex) { 
            System.out.println("\n*** SQLException caught ***\n" + ex.getMessage());
         }
         catch (Exception e) { 
            System.out.println("\n*** other Exception caught ***\n" + e.getMessage());
         }

      } while (choice != 7); // Closes the do-while loop

      // Close after the user picks option 7
      conn.close();
      System.out.println("Database connection closed.");

   } // End main


   // -----------------------------------------
   // HELPER FUNCTIONS
   // -----------------------------------------
   
   private static String prompt(
         BufferedReader in,
         String message) throws IOException {

      System.out.print(message);
      return in.readLine();
   }

   private static void printMenu()
   {
      System.out.println("========================================");
      System.out.println("       SCHOOL REGISTRATION SYSTEM       ");
      System.out.println("========================================");
      System.out.println("1. Show All Students (Task 2)");
      System.out.println("2. Show Students in a Class (Task 3)");
      System.out.println("3. Get Course Prerequisites (Task 4)");
      System.out.println("4. Enroll Graduate Student (Task 5)");
      System.out.println("5. Drop Graduate Student (Task 6)");
      System.out.println("6. Delete Student (Task 7)");
      System.out.println("7. Exit");
      System.out.print("Enter your choice (1-7): ");
   }

} // End class
