/****************************************************
    * @author         :   C1STAGILE-57089
    * @created        :   20/02/2023
    * @description    :   controller to aura Component ProtocolSolicitationStatusQuickAction.
    * @return         :   String
    ******************************************************/ 
    public with sharing class ProtSolicitationStatusReqController {
        
        /****************************************************
        * @Method         :   getDiscountStateMap
        * @author         :   C1STAGILE-57089
        * @created        :   21/02/2023
        * @description    :   to take Status map
        * @return         :   Map<String, String>
        ******************************************************/    
        public static Map<String, String> getDiscountStateMap(){
            Map<String, String> stateMap = new Map<String, String>();
            stateMap.put('NONE', System.Label.CC_None);
            stateMap.put('PENDING', System.Label.ASD_Pending);
            stateMap.put('ACCEPTED', System.Label.Accepted);
            stateMap.put('REJECTED', System.Label.Rejected);
            return stateMap;
        }
        
        /****************************************************
        * @Method         :   getPickListValuesIntoList
        * @author         :   C1STAGILE-57089
        * @created        :   21/02/2023
        * @description    :   to take FCA Brands
        * @return         :   Map<String, String>
        ******************************************************/ 
        @AuraEnabled        
        public static Map<String, String> getPickListValuesIntoList(){
    
            Map<String, String> options = new Map<String, String>();
    
            Schema.DescribeFieldResult fieldResult = Account.FCA_Brands__c.getDescribe();
    
            List<Schema.PicklistEntry> pValues = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry p: pValues) {
                options.put(p.getValue(), p.getLabel());
            }
            return options;
        }
        /****************************************************
        * @Method         :   getPickListValuesStatus
        * @author         :   C1STAGILE-57089
        * @created        :   21/02/2023
        * @description    :   to take Status map
        * @return         :   Map<String, String>
        ******************************************************/ 
        @AuraEnabled        
        public static Map<String, String> getPickListValuesStatus(){
            Map<String, String> statusMap = new Map<String, String>();
            statusMap.put('All', System.Label.OWC_All_channels);
            statusMap.put('WAITING_FOR_ASSIGNMENT', System.Label.WaitingForAssignment);
            statusMap.put('IN_PROGRESS', System.Label.MKTInProgress);
            statusMap.put('REJECTED', System.Label.Rejected);
            statusMap.put('ACCEPTED', System.Label.Accepted);
            return statusMap;
    
        }
    
        /****************************************************
        * @Method         :   getEndpoint
        * @author         :   C1STAGILE-57089
        * @created        :   21/02/2023
        * @description    :   to take Status map
        * @return            List<RowWrapper> 
        * @param             brand String Brand 
        * @param             dealer  String 
        * @param             minCreationDate DateTime 
        * @param             solicitationState String 
        * @param             recordId String 
        ******************************************************/ 
        @AuraEnabled
        public static List<RowWrapper>  getEndpoint(String brand, String dealer, DateTime minCreationDate, String solicitationState, String recordId){
            Account acc = [SELECT TECH_FiscalID__c FROM Account WHERE Id = :recordId WITH SECURITY_ENFORCED LIMIT 1];
            
            String customernationalid = acc.TECH_FiscalID__c;
            
            String dealernumber = '';
            Account dealerAcc = [SELECT FCA_Dealer_Code__c, FCA_Dealer_Outlet__c FROM Account WHERE Id = :dealer WITH SECURITY_ENFORCED];
            
            if(Constants.SET_FCA_BRANDS.contains(Brand)){
                dealernumber = dealerAcc.FCA_Dealer_Code__c;
            }else{
                String siteGeoId = dealerAcc.FCA_Dealer_Outlet__c  + '_' + Brand;
                Account dealerAccPSA = [SELECT VNContractNumber__c FROM Account WHERE FCA_SiteGeoId__c =: siteGeoId WITH SECURITY_ENFORCED];
                dealernumber = dealerAccPSA.VNContractNumber__c;
            }
           
            User us = PAd.getCurrentUser(userInfo.getUserId()).get(0);
            String country = us.Country__c;
            String json;
            
            String url = '';
            url += (!String.isBlank(dealernumber))? 'dealernumber=' + dealernumber + '&' : 'dealernumber='+ '&';
            url += (!String.isBlank(country))? 'country=' + country + '&' : 'country='+ '&';
            url += (!String.isBlank(brand))? 'brand=' + brand + '&' : 'brand='+ '&';
            url += (!String.isBlank(customernationalid))? 'customernationalid=' + customernationalid + '&' : 'customernationalid='+ '&';
            url += (!String.isBlank(recordId))? 'c1stcustomerid=' + recordId + '&' : 'c1stcustomerid='+ '&';
            url += (minCreationDate != null)? 'minimalcreationdate=' + minCreationDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') + '&' : 'minimalcreationdate='+ '&';
            url += (!String.isBlank(SolicitationState))? 'solicitationstate=' + SolicitationState : 'solicitationstate=';
    
            
            try{
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Int270Endpoint?'+ url);
            req.setMethod('GET');
            req.setHeader('client_id', '{!$Credential.UserName}');
            req.setHeader('client_secret', '{!$Credential.Password}');
            req.setHeader('Content-Type','application/json');
            req.setTimeout(12000);
    
            System.debug(LoggingLevel.DEBUG, 'setEndpoint : ' + req.getEndpoint());
    
            Http http = new Http();
            HttpResponse response = new HttpResponse();
            response = http.send(req);
            
            System.debug(LoggingLevel.DEBUG, 'Response : ' + response.getBody());
            
            json = response.getBody().replaceAll('\n',' ');

            } catch(Exception e){
                System.debug(LoggingLevel.ERROR, 'ERROR : ' + e.getMessage());
            }
            
            SolicitationRequestWrapper.SolicitationResponse solicitation = (SolicitationRequestWrapper.SolicitationResponse) System.JSON.deserialize(json,SolicitationRequestWrapper.SolicitationResponse.class);
            
            List<RowWrapper> dataList = new List<RowWrapper>();
            Integer counter = 1;
            
            Boolean partialResponse = solicitation.partialResponse;
            
            Map<String, String> statusMap = getPickListValuesStatus();
            if(solicitation.totalDiscountCount == 0) {
                RowWrapper rowWrapper = new RowWrapper();
                rowWrapper.id = '0';
                rowWrapper.solicitationState = statusMap.get(solicitationState);
                dataList.add(rowWrapper);
            } else {
                
                Map<String, String> discountStateMap = getDiscountStateMap();
                
                if(solicitation.solicitationList != null) {
                    for(SolicitationRequestWrapper.solicitationList request : solicitation.solicitationList) {
                        String promoCode = request.promocode;
                        String solicitationComment = request.solicitationComment;
                        String protocolId = request.protocolId;
                        String solicitState = request.solicitationState;
                        for(SolicitationRequestWrapper.DiscountRequestList discount : request.discountRequestList ) {
                            RowWrapper rowWrapper = new RowWrapper();
            
                            rowWrapper.id = String.valueOf(counter);
                            rowWrapper.promoCode = promoCode;
                            rowWrapper.solicitationComment = solicitationComment;
                            rowWrapper.protocolId = protocolId;
                            rowWrapper.solicitationState = statusMap.get(solicitState);
                            rowWrapper.carModelName = discount.carModelName;
                            rowWrapper.volume = String.valueOf(discount.volume);
                            rowWrapper.requestDiscount = discount.requestDiscount == null ? '' : String.valueOf(discount.requestDiscount) + '%';
                            rowWrapper.discountRequestState = discountStateMap.get(discount.discountRequestState);
                            rowWrapper.approvedDiscount = discount.approvedDiscount == null ? '' : String.valueOf(discount.approvedDiscount) + '%';
                            rowWrapper.partialResponse = partialResponse;
                        
                            dataList.add(rowWrapper);
                            counter++;
                        }
                    }
                }
                
            }
            
    
            return dataList;
    
        }
    
        /**  @description     : Wrapper class to send information to aura component */ 
        public class RowWrapper{
            @AuraEnabled   
            public String id; 
            @AuraEnabled   
            public String promoCode;
            @AuraEnabled   
            public String solicitationComment;
            @AuraEnabled   
            public String protocolId;
            @AuraEnabled   
            public String solicitationState;
            @AuraEnabled   
            public String carModelName; 
            @AuraEnabled   
            public String volume;   
            @AuraEnabled   
            public String requestDiscount;  
            @AuraEnabled   
            public String discountRequestState;  
            @AuraEnabled   
            public String approvedDiscount; 
            @AuraEnabled   
            public Boolean partialResponse;
        }
    }
