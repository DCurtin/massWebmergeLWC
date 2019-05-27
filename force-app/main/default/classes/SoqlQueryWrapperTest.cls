@isTest
public class SoqlQueryWrapperTest {
    static testmethod void generallAssignmentTest_setAllVariablesInWrapperClass_allValuesShouldMatchWhatTheyAreAssigned()
    {
        string testString='testString';

        soqlQueryWrapper testWrapper = new soqlQueryWrapper();
        testWrapper.query = testString;
        testWrapper.description = testString;
        testWrapper.filterFieldPath = testString;
        testWrapper.filterValue = testString;
        testWrapper.webmergeMappingName = testString;

        System.assertEquals(testWrapper.query, testString);
        System.assertEquals(testWrapper.description, testString);
        System.assertEquals(testWrapper.filterFieldPath, testString);
        System.assertEquals(testWrapper.filterValue, testString);
        System.assertEquals(testWrapper.webmergeMappingName, testString);

    }
}
