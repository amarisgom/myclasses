/**
	*   @Class 			: 	CNT_RelationshipPage
	*   @Author         :   Azahara Mariscal
	*   @Created        :   07 Jul 2023
	*   @description    :   Controller Class for Lwc_RelationshipPage
**/
public with sharing class CNT_RelationshipPage {
    /**
	*   @description    :   Method to take relation info
    *   @param           recordId 
    *   @return          map<String, List<Relationship__c>>
    **/
    @AuraEnabled
    public static map<String,  List<Relationship__c>> getRecords(String recordId) {
        map<String, List<Relationship__c>> returnValue = new map<String,  List<Relationship__c>>();
        List<Relationship__c> relations = [SELECT Id, REL_PCK_Type__c, toLabel(REL_PCK_RelationType__c),REL_CHK_isAutomatic__c, REL_FOR_RelationType__c,
                                                  REL_LKP_relatedAccount1__c, REL_LKP_relatedAccount1__r.Name, 
                                                  REL_LKP_relatedAccount2__c ,REL_LKP_relatedAccount2__r.Name
                                           FROM Relationship__c 
                                           WHERE REL_LKP_relatedAccount1__c = :recordId OR REL_LKP_relatedAccount2__c = :recordId
                                           WITH SECURITY_ENFORCED ];

        List<Relationship__c> bus1 = new List<Relationship__c>();
        returnValue.put('BUS1', bus1);
        List<Relationship__c> bus2 = new List<Relationship__c>();
        returnValue.put('BUS2', bus2);
        List<Relationship__c> fri1 = new List<Relationship__c>();
        returnValue.put('FRI1', fri1);
        List<Relationship__c> fri2 = new List<Relationship__c>();
        returnValue.put('FRI2', fri2);
        List<Relationship__c> fam1 = new List<Relationship__c>();
        returnValue.put('FAM1', fam1);
        List<Relationship__c> fam2 = new List<Relationship__c>();
        returnValue.put('FAM2', fam2);
        for(Relationship__c rel : relations){
            if(rel.REL_LKP_relatedAccount1__c == recordId){
                if(rel.REL_PCK_Type__c == 'BUS'){
                    bus1.add(rel);
                    returnValue.put('BUS1', bus1);
                }else if(rel.REL_PCK_Type__c == 'FRI'){
                    fri1.add(rel);
                    returnValue.put('FRI1', fri1);
                }else{
                    fam1.add(rel);
                    returnValue.put('FAM1', fam1);
                }
            }else{
                if(rel.REL_PCK_Type__c == 'BUS'){
                    bus2.add(rel);
                    returnValue.put('BUS2', bus2);
                }else if(rel.REL_PCK_Type__c == 'FRI'){
                    fri2.add(rel);
                    returnValue.put('FRI2', fri2);
                }else{
                    fam2.add(rel);
                    returnValue.put('FAM2', fam2);
                }
            }
        }
        
        return returnValue;
    }
    /**
	*   @description    :   Method to take relation info
    *   @param           recordId 
    *   @return          map<String, sObject>
    **/
    @AuraEnabled
    public static List<sObject> getAccountInfo(String recordId) {
        List<sObject> returnValue = new List<sObject>();
        Account acc = [ SELECT Id, Name, RecordType.Name FROM Account WHERE Id =: recordId WITH SECURITY_ENFORCED];
        returnValue.add(acc);

        return returnValue;
    }
    /**
	*   @description    :   Method to take relation info
    *   @param           objApiName 
    *   @param           fieldName 
    *   @return          List < Map < String, String >>
    **/
    @AuraEnabled
    public static List < Map < String, String >> getPickListValues(String objApiName, String fieldName) {
        List < Map < String, String >> options = new List < Map < String, String >> ();
        Map < String, Schema.SObjectType > objGlobalMap = Schema.getGlobalDescribe();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objApiName);
        if (objType == null) {
            return options;
        }
        Schema.DescribeSObjectResult sobjectDescribe = objType.getDescribe();
        Map < String, Schema.SObjectField > fieldMap = sobjectDescribe.fields.getMap();
        if (fieldMap.get(fieldName) == null) {
            return options;
        }
        List < Schema.PicklistEntry > pickListValues = fieldMap.get(fieldName).getDescribe().getPickListValues();
        for (Schema.PicklistEntry f: pickListValues) {
            Map < String, String > values = new Map < String, String > {
                'label' => f.getLabel(),
                'value' => f.getValue()
            };
            options.add(values);
        }
        return options;
    }
    @AuraEnabled
    /**
      * @description Method to get account records by typed Name
      * @param typedName name
      * @return  Name String
      */
    public static string getAccounts(String typedName){
        
        List<String> accountStatus = new list<String>{'EXT', 'EXA', 'TAN', 'TBO', 'AAN', 'ABO'};
        List<List<SObject>> retrievedRecords = new List<List<SObject>>();
        
        retrievedRecords = [Find :typedName IN ALL FIELDS RETURNING Account(name,ACC_TXT_NIFNIECIF__c WHERE ACC_PCK_Status__c NOT IN :accountStatus AND ACC_FOR_AgentView__c = true) ];
        
        return JSON.serialize(retrievedRecords[0]);

    }

    @AuraEnabled
    /**
      * @description Method to get account records by typed Name
      * @param recordId string
      * @param AccountId string
      * @param type string
      * @param etiqueta string
      * @return String
      */
    public static void createRelation(String recordId, String accountId, String type, String etiqueta){

        Relationship__c newRel = new Relationship__c ();
        newRel.REL_LKP_relatedAccount1__c = recordId;
        newRel.REL_LKP_relatedAccount2__c = accountId;
        newRel.REL_PCK_Type__c = type;
        newRel.REL_PCK_RelationType__c = etiqueta;
    
        
        insert newRel;
            
  
    }
    @AuraEnabled
    /**
      * @description Method to get account records by typed Name
      * @param recordId List<string>
    */
    public static void deleteRelation(List<String> recordId){
        List<Relationship__c> deleteRecord = [Select Id from Relationship__c where id IN: recordId WITH SECURITY_ENFORCED];

        delete deleteRecord;
    }
    @AuraEnabled
    /**
      * @description edit relation
      * @param recordId List<string>
      * @param etiqueta
    */
    public static void editRelation(List<String> recordId, String etiqueta){
        List<Relationship__c> editRecord = [Select Id, REL_PCK_RelationType__c from Relationship__c where id IN: recordId WITH SECURITY_ENFORCED];

        for(Relationship__c rel : editRecord){
            rel.REL_PCK_RelationType__c = etiqueta;
        }

        update editRecord;
    }
}
