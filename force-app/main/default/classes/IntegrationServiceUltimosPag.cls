public without sharing class IntegrationServiceUltimosPag {
    public IntegrationServiceUltimosPag() {

    }

    @AuraEnabled (Cacheable=true)
    public static List<returnPagamento> getPagamentos(){
        List<dataPagamento> datalist = new List<dataPagamento>();
        List<returnPagamento> returnList = new List<returnPagamento>(); 

        String jsonstr;

        User user = [SELECT Id, Name, CPF__c FROM User WHERE Id =: UserInfo.getUserId()];  
        System.debug('Usuário: ' + user.Name + ' CPF: ' + user.CPF__c);
        
        String cpf = user.CPF__c;
        

        if(cpf != null && cpf != ''){
            jsonstr = IntegrationConnectUltimosPag.getUltimosPagService(cpf);
        }
        System.debug('jsonstr' +jsonstr);
        if(jsonstr != ''){
            dataPagamento jsond = (dataPagamento)JSON.deserialize(jsonstr, dataPagamento.class); 
            system.debug('jsond ' + jsond);
            system.debug('datalist ' + datalist);
            if(jsond != null) {
                for(consultaPagamento ap : jsond.data){                    
                    returnPagamento ret = new returnPagamento();
                    ret.sistema = ap.sistema;
                    ret.competencia = ap.competencia;
                    ret.apolice = ap.apolice;
                    ret.apoliceDisplay = ap.apoliceDisplay;
                    ret.nrSub = ap.nrSub;
                    ret.dtVencimento =  IntegrationConnectUltimosPag.convertStringToDate(ap.dtVencimento);
                    ret.dtPagamento = IntegrationConnectUltimosPag.convertStringToDate(ap.dtPagamento);
                    ret.chaveParcelaLegado = ap.chaveParcelaLegado;
                    ret.valor = ap.valor;
                    if(ap.formaPagamento == 'BOLETO'){
                        ret.formaPagamento = 'Boleto';

                    } else if(ap.formaPagamento == 'CARTAO'){
                        ret.formaPagamento = 'Cartão de Crédito';

                    } else if(ap.formaPagamento == 'DEBITO'){
                        ret.formaPagamento = 'Débito em Conta';

                    } else {
                        ret.formaPagamento = ap.formaPagamento;
                    }
                    returnList.add(ret);
                }
                System.debug('RETORNO PAGAMENTO' + returnList);
            }
        }

        return returnList;
    }

    @AuraEnabled (Cacheable=true)
    public static List<returnPagamentoVencidos> getPagamentosVencidos(){
        List<dataPagamentoVencidos> datalist = new List<dataPagamentoVencidos>();
        List<returnPagamentoVencidos> returnList = new List<returnPagamentoVencidos>();

        String jsonstr;

        User user = [SELECT Id, Name, CPF__c FROM User WHERE Id =: UserInfo.getUserId()];
        System.debug('Usuário: ' + user.Name + ' CPF: ' + user.CPF__c);

        String cpf = user.CPF__c;
        

        if(cpf != null && cpf != ''){
            jsonstr = IntegrationConnectUltimosPag.getVencerVencidoService(cpf);
        }
        System.debug('jsonstr' +jsonstr);
        if(jsonstr != ''){
            dataPagamentoVencidos jsond = (dataPagamentoVencidos)JSON.deserialize(jsonstr, dataPagamentoVencidos.class); 
            system.debug('jsond ' + jsond);
            system.debug('datalist ' + datalist);
            if(jsond != null) {
                for(consultaPagamentoVencidos ap : jsond.data){                    
                    returnPagamentoVencidos ret = new returnPagamentoVencidos();
                    ret.sistema = ap.sistema;
                    ret.competencia = ap.competencia;
                    ret.apolice = ap.apolice;
                    ret.apoliceDisplay = ap.apoliceDisplay;
                    ret.fatura = ap.fatura;
                    ret.dtVencimento = IntegrationConnectUltimosPag.convertStringToDate(ap.dtVencimento);
                    ret.diasVencido = ap.diasVencido;
                    ret.chaveParcelaLegado = ap.chaveParcelaLegado;
                    ret.valor = ap.valor;
                    ret.ColetivoSn = ap.ColetivoSn;

                    if(ap.formaPagamento == 'BOLETO'){
                        ret.formaPagamento = 'Boleto';

                    } else if(ap.formaPagamento == 'CARTAO'){
                        ret.formaPagamento = 'Cartão de Crédito';

                    } else if(ap.formaPagamento == 'DEBITO'){
                        ret.formaPagamento = 'Débito em Conta';

                    } else {
                        ret.formaPagamento = ap.formaPagamento;
                    }
                    returnList.add(ret);
                }
                System.debug('RETORNO PAGAMENTO' + returnList);
            }
        } 

        return returnList;
    }
    @AuraEnabled (Cacheable=true)
    public static String getBoletos(String apolice, String fatura){
        
        System.debug('** US 2127 - getBoletos apolice = ' + apolice);
        System.debug('** US 2127 - getBoletos fatura = ' + fatura);        
        
        String method = 'GET';
        String retorno = '';
        String url = '';
        String jsonBoleto;
        User user = [SELECT Id, Name, FirstName, LastName, CPF__c, ContactId, contact.email, contact.AccountId FROM User WHERE Id =: UserInfo.getUserId()];
        String body = '';    
        String jsonstr;
        dataDownload jsonds;
        String cpf = user.CPF__c;
        

        jsonstr = IntegrationConnectUltimosPag.getVencerVencidoService(cpf);
        System.debug('**  US 2127 - jsonstr = ' + jsonstr);           
        dataPagamentoVencidos jsond = (dataPagamentoVencidos)JSON.deserialize(jsonstr, dataPagamentoVencidos.class);
        if(jsond != null) {
            System.debug('**  US 2127 - jsond: ' + jsond);
            for(consultaPagamentoVencidos ap : jsond.data){                    
                returnPagamentoVencidos ret = new returnPagamentoVencidos();
                ret.chaveParcelaLegado = ap.chaveParcelaLegado;
                ret.sistema = ap.sistema;
                ret.linkBoleto = ap.linkBoleto;
                System.debug('ret: ' + ret);     
    
                if(ret.chaveParcelaLegado == fatura)
                {
                    body = '{"chaveParcelaLegado":"'+ret.chaveParcelaLegado+'","sistema": "'+ret.sistema+'","link": "'+ret.linkBoleto+'"}';   
                }                
                
                System.debug('** US 2127 - body ' + body);
            }
            
            jsonBoleto =  IntegrationConnectUltimosPag.getBoletoService(body);
            System.debug('** jsonBoleto = ' + jsonBoleto);
            jsonds = (dataDownload)JSON.deserialize(jsonBoleto, dataDownload.class);           
            System.debug('** US 2127 - Integração 2 ' + jsonds.data);
        } 
     
        return jsonds.data;
    }
    @AuraEnabled
    public static retornoSaveCase sendCaseFormaPagamento(String apolice, String fatura, String cobranca){
        retornoSaveCase retornoCase = new retornoSaveCase();
        List<Case> casoAberto = new List<Case>();
        string result = '';
        Case criarCaso = new Case();
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Caso_Padrao').getRecordTypeId();

        system.debug('Fatura ' + fatura);
        system.debug('apolice ' + apolice);
        User user = [SELECT Id, Name, CPF__c, ContactId, contact.email, contact.AccountId FROM User WHERE Id =: UserInfo.getUserId()];
        String cpf = user.CPF__c;
        

        String statusCase = 'Em andamento';
        String assuntoCase = 'Segunda via - Envio de 2a via de boleto';
        system.debug(user.contact.AccountId + ' ' + statusCase + ' ' + assuntoCase + ' ' + cobranca);
        String teste =  cobranca.trim();

        casoAberto = [SELECT Id, CaseNumber, Status, AccountId, Assunto__c, Doc_Cobranca__c, recordTypeId FROM Case WHERE AccountId = :user.contact.AccountId AND Status = :statusCase AND Assunto__c = :assuntoCase AND Doc_Cobranca__c = :teste];
        system.debug('caso Aberto ' + casoAberto);
        
        if(casoAberto.size() == 0){
            System.debug('ENTROU');

            AssignmentRule AR = new AssignmentRule();
            AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
            criarCaso.setOptions(dmlOpts);
            criarCaso.RecordTypeId = recordTypeId;
            criarCaso.Status = 'Em andamento';
            criarCaso.Type = 'Segunda via';
            criarCaso.Motivo_do_Contato__c = 'Envio de 2a via de boleto';
            criarCaso.Origin = 'Portal do Segurado';
            criarCaso.ContactId = user.ContactId;
            criarCaso.AccountId = user.contact.AccountId;
            criarCaso.Apolice__c = apolice;
            criarCaso.Doc_Cobranca__c = cobranca;
            criarCaso.Fatura__c = fatura;

            String jsonstr = IntegrationConnectUltimosPag.getVencerVencidoService(cpf);
            dataPagamentoVencidos jsond = (dataPagamentoVencidos)JSON.deserialize(jsonstr, dataPagamentoVencidos.class);
            if(jsond != null) {
                System.debug('jsond: ' + jsond);
                for(consultaPagamentoVencidos ap : jsond.data){                    
                    returnPagamentoVencidos ret = new returnPagamentoVencidos();
                    ret.competencia = ap.competencia;
                    ret.apolice = ap.apolice;
                    ret.fatura = ap.fatura;
                    ret.valor = ap.valor;
                    System.debug('ret: ' + ret);
                    criarCaso.Description = 'Solicito boleto atualizado referente à: '
                    +'Competência: ' + ret.competencia + ' ' +
                    'Apólice: ' + ret.apolice + ' ' +
                    'Fatura: ' + ret.fatura + ' ' +
                    'Valor: ' + ret.valor;
                }
            } 
            System.debug('Descrição: ' + criarCaso.Description);
            try{
                if(criarCaso.Description != ''){
                    System.debug('Contact: ' + criarCaso.Description);
                    insert criarCaso;
                }
                Case getNumber = [SELECT Id, CaseNumber FROM Case WHERE Id = :criarCaso.Id];
                if(getNumber.CaseNumber != null){
                    result = getNumber.CaseNumber;
                    retornoCase.numberCaseNew = getNumber.CaseNumber;
                    retornoCase.success = true;
                }
                system.debug('RESULTADO: ' + result);

            }catch(Exception ex){
                System.debug('Erro ao criar caso ' + ex);
            }
        } else{
            retornoCase.existe = true;
            retornoCase.numberCaseExiste = casoAberto.get(0).CaseNumber;
            result = 'existe';
        }
        return retornoCase;
    }

    public class dataPagamento{
        @AuraEnabled public Boolean success; 
        @AuraEnabled public List<consultaPagamento> data; 

    }

    public class consultaPagamento{
        @AuraEnabled public String sistema;    
        @AuraEnabled public string competencia;
        @AuraEnabled public string apolice;
        @AuraEnabled public string apoliceDisplay;
        @AuraEnabled public string nrSub;
        @AuraEnabled public string endosso;     
        @AuraEnabled public string valor;       
        @AuraEnabled public string dtVencimento;           
        @AuraEnabled public string dtPagamento;           
        @AuraEnabled public string formaPagamento;  
        @AuraEnabled public string chaveParcelaLegado;         

    } 
    public class retornoSaveCase{
        @AuraEnabled public Boolean success; 
        @AuraEnabled public Boolean existe; 
        @AuraEnabled public String numberCaseExiste; 
        @AuraEnabled public String numberCaseNew; 

    }
    public class returnPagamento{
        @AuraEnabled public String sistema;    
        @AuraEnabled public string competencia;
        @AuraEnabled public string apolice;
        @AuraEnabled public string apoliceDisplay;
        @AuraEnabled public string nrSub;
        @AuraEnabled public string endosso;     
        @AuraEnabled public string valor;       
        @AuraEnabled public string dtVencimento;           
        @AuraEnabled public string dtPagamento;           
        @AuraEnabled public string formaPagamento;   
        @AuraEnabled public string chaveParcelaLegado;       
    }
    
    
    public class dataPagamentoVencidos{
        @AuraEnabled public Boolean success; 
        @AuraEnabled public List<consultaPagamentoVencidos> data; 
    }
    public class dataDownload{
        @AuraEnabled public Boolean success; 
        @AuraEnabled public String data; 
    }
    public class consultaPagamentoVencidos{
        @AuraEnabled public String sistema;    
        @AuraEnabled public string competencia;
        @AuraEnabled public string apolice;
        @AuraEnabled public string apoliceDisplay;
        @AuraEnabled public string nrSub;
        @AuraEnabled public string fatura;     
        @AuraEnabled public string valor;       
        @AuraEnabled public string dtVencimento;           
        @AuraEnabled public string diasVencido;           
        @AuraEnabled public string formaPagamento;  
        @AuraEnabled public string chaveParcelaLegado;    
        @AuraEnabled public string linkBoleto;     
        @AuraEnabled public string ColetivoSn;     

    } 
    public class returnPagamentoVencidos{
        @AuraEnabled public String sistema;    
        @AuraEnabled public string competencia;
        @AuraEnabled public string apolice;
        @AuraEnabled public string apoliceDisplay;
        @AuraEnabled public string nrSub;
        @AuraEnabled public string fatura;     
        @AuraEnabled public string valor;       
        @AuraEnabled public String dtVencimento;           
        @AuraEnabled public String diasVencido;           
        @AuraEnabled public string formaPagamento;   
        @AuraEnabled public string chaveParcelaLegado;
        @AuraEnabled public string linkBoleto;       
        @AuraEnabled public string ColetivoSn;       
    }

}