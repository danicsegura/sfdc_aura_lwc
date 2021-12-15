({
    doInit : function(component, event, helper){
        console.log(component.get("v.recordId"));
    },
    
    handleLoad : function(component, event, helper){
        var changeType = event.getParams().changeType;
        if(changeType === "ERROR"){
            console.log('Erro no carregamento de página.');
        }else{
			helper.buscarLimiteCredito(component);
        }
    },
})