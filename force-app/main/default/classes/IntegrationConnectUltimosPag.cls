global without sharing class IntegrationConnectUltimosPag {
    public IntegrationConnectUltimosPag() {}

    public static String getToken(){

        String result;
        requestCallout requestCallout = gerarEndPoint('AccessToken', '');
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setMethod( requestCallout.metodo );
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody(requestCallout.body);
        request.setEndpoint( requestCallout.endpoint );
        System.debug('$$ endpoint: ' + request.getEndpoint());

        try{
            HttpResponse response = http.send( request );
            if(response.getStatusCode() == 200 && !String.isBlank(response.getBody())){
                JsonResponse jresp = (JsonResponse)JSON.deserialize(response.getBody(), JsonResponse.class);
                System.debug(jresp);
                result = jresp.access_token;
                System.debug(result);
            }else {
                System.debug('ERROR ' + response.getStatusCode());
            }
        }catch(CalloutException e){
           System.debug('Error: ' + e.getMessage());
        }
        return result;
    }

    public static string getUltimosPagService(String cpf){
        String result;
        requestCallout requestCallout = gerarEndPoint('ParcelaPaga', cpf);

        String access_token = getToken();
        System.debug('Token de Acesso 2: ' + access_token);
        if(access_token != ''){

            Http http = new Http();
            HttpRequest request = new HttpRequest();
    
            request.setMethod( requestCallout.metodo );
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + access_token);
            request.setTimeout(requestCallout.timeout);
            request.setEndpoint(requestCallout.endpoint);
            System.debug(request);
            try{
                HttpResponse response = http.send( request );
                System.debug('response ' + response);
                if(response.getStatusCode() == 200 && !String.isBlank(response.getBody())){
                    result = response.getBody();
                    System.debug(result);
                }else {
                    System.debug('Return: ' + response.getStatusCode());
                    result = '';
                }
            }catch(CalloutException e){
               System.debug('Error: ' + e.getMessage());
            }
        }
        return result;
    }
    public static string getBoletoService(String body){
        String result;
        requestCallout requestCallout = gerarEndPoint('DownloadBoleto', '');

        String access_token = getToken();
        System.debug('Token de Acesso: ' + access_token);

        if(access_token != ''){                                                                                   

            Http http = new Http();
            HttpRequest request = new HttpRequest();
    
            request.setMethod(requestCallout.metodo);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + access_token);
            request.setBody(body);
            request.setTimeout(requestCallout.timeout);
            request.setEndpoint(requestCallout.endpoint);
            try{
                HttpResponse response = http.send( request );
                System.debug('response connect ' + response);
                if(response.getStatusCode() == 200 && !String.isBlank(response.getBody())){
                    result = response.getBody();
                }else {
                    System.debug('Return: ' + response.getStatusCode());
                    result = null;
                }
            }catch(CalloutException e){
               System.debug('Error: ' + e.getMessage());
            }
        }
        return result;
    }

    public static string getVencerVencidoService(String cpf){
        String result;
        requestCallout requestCallout = gerarEndPoint('ParcelaAberta', cpf);
        String access_token = getToken();
        System.debug('Token de Acesso 2: ' + access_token);
        if(access_token != ''){

            Http http = new Http();
            HttpRequest request = new HttpRequest();
    
            request.setMethod( requestCallout.metodo);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + access_token);
            request.setTimeout(requestCallout.timeout);
            request.setEndpoint(requestCallout.endpoint);
            System.debug(request);
            try{
                HttpResponse response = http.send( request );
                System.debug('response ' + response);
                if(response.getStatusCode() == 200 && !String.isBlank(response.getBody())){
                    result = response.getBody();
                    System.debug(result);
                }else {
                    System.debug('Return: ' + response.getStatusCode());
                    result = '';
                }
            }catch(CalloutException e){
               System.debug('Error: ' + e.getMessage());
            }
        }
        return result;
    }
    public static requestCallout gerarEndPoint(String serviceName, String params){
        requestCallout request = new requestCallout();
        Servicos__mdt servico = [SELECT Id, Metodo__c, Timeout__c, Endpoint__c, NamedCredential__c, Service_Name__c, Body__c  FROM Servicos__mdt WHERE Service_Name__c = :serviceName];
        
        if(servico != null){    
            request.endpoint =  'callout:' + servico.NamedCredential__c + servico.Endpoint__c + params;
            request.metodo = servico.Metodo__c;
            request.body = servico.Body__c;
            request.timeout = Integer.valueOf(servico.Timeout__c);
        }

        return request;
    }
    public class requestCallout{
        public String endpoint; 
        public String metodo; 
        public Integer timeout;
        public String body; 
    }

    global class JsonResponse{
        global string access_token; 
        global string  expires_in;
        global string token_type;
    }
    global class JsonResponsePagamento{
        global string data; 
    }
    global class JsonResponseBoleto{
        global string data; 
    }
    public static String convertStringToDate(String value){
        String retorno;
        String dateString;
        try {
            system.debug('DATA ' + value);
            if(String.isNotBlank(value)){

                String dateFormatString = 'dd/MM/yyyy';
                Date d = Date.valueOf(value);

                Datetime dt = Datetime.newInstance(d.year(), d.month(),d.day());
                if(dt.year() == 1900){
                    dateString = 'A vista';
                } else {
                    dateString = dt.format(dateFormatString);
                }
                System.debug(dateString); 

                retorno = dateString;
            }
        } catch(Exception ex) {
            System.debug('Error: ' + ex.getMessage() + ' Cause: ' + ex.getCause() + ' Trace: ' + ex.getStackTraceString());
            return null;
        }
        return retorno;
    }
}