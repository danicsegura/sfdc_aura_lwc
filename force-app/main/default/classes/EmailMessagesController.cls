/***********************************************************************************************************************************************
 * Copyright © 2022 VIBRA Distribuidora
 * ==============================================================================================================================================
 * Purpose: Classe controller do componente LWC viewEmailMessages
 * ==============================================================================================================================================
 * History
 * -------
 * VERSION 	AUTHOR 		    DATE    		DETAIL 		Description
 * 1.0 		Daniela Segura 	21/07/2022 		Created 	US 18649 - Versão inicial
 ***********************************************************************************************************************************************/
public with sharing class EmailMessagesController {

    /******************************************************************************************************************************************
     *  Purpose: @description Obter a lista de mensagens de email
     *  Parameters: String recordId
     *  Returns: @return List<EmailMessage>
     *  Throws -
     * ========================================================================================================================================
     * History
     * -------
     * VERSION      AUTHOR          DATE           DETAIL      Description
     * 1.0          Daniela Segura  21/07/2022     Created     US 18649 - Versão inicial
    ******************************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<EmailMessage> getEmailMessages(String recordId){
        
        PurgeEmailMessageAWSIntegration busca = new PurgeEmailMessageAWSIntegration();
        Busca.recordId = recordId;
        GetEmailMessageAWSIntegration buscar = new GetEmailMessageAWSIntegration();
        busca.informarProximo(buscar);
        
        busca.buscarEmails();
        return buscar.retEmailMassageList;
    }
}
