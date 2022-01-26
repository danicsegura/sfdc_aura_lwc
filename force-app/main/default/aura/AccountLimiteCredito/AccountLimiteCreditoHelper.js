({
    buscarLimiteCredito : function(component) {
        var action = component.get("c.callService");
        action.setParams({ cnpj : component.get("v.accountRecord.Numero_Do_Documento__c")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                let executadaCorretamente = response.getReturnValue().StatusExecucao.ExecutadaCorretamente;
                let mensagemErro = response.getReturnValue().StatusExecucao.Mensagem;
                
                if(!executadaCorretamente) return;
                if(mensagemErro != null) this.sinalizarErro(component, mensagemErro);
                
                this.atribuirValores(component, response.getReturnValue());
            } else{
                this.sinalizarErro(component, 'Ocorreu um erro na integração. '+ response.getError() != null ? response.getError().errors[0].message : 'Erro desconhecido.');
            }
        });
        $A.enqueueAction(action);
    },
    
    atribuirValores : function(component, payload){
        let contaCliente = payload.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.ContaCliente;
        let limiteCredito = payload.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.LimiteCredito;
        let totalCompromisso = payload.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.TotalCompromisso;
        let verificacaoSeguinte = payload.RetornoConsultaCreditoClienteCRM.AdministracoesCredito.VerificacaoSeguinte;
        
        component.set("v.contaCliente", contaCliente);
        component.set("v.limiteCredito", limiteCredito);
        component.set("v.compromissoTotal", totalCompromisso);
        component.set("v.verificacaoSeguinte", verificacaoSeguinte == null ? '-' : verificacaoSeguinte);
        component.set("v.integracaoConcluida", true);
    },
    
    sinalizarErro : function(component, mensagemErro) {
        component.set("v.mensagemErro", mensagemErro);
        component.set("v.clienteInvalido", true);
        return true;
    },
})