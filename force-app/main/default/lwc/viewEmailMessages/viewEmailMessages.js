import { LightningElement, api, wire } from "lwc";
import getEmailMessages from "@salesforce/apex/EmailMessagesController.getEmailMessages";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";

export default class ViewEmailMessages extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  messages = [];
  openPopover = false;
  showSpinner = true;

  @wire(getEmailMessages, { recordId: "$recordId" })
  wiredMessages({ error, data }) {
    if (data) {
      this.messages = this.sortByDateDesc(JSON.parse(JSON.stringify(data)));

      if (this.messages.length == 0) {
        this.showNotification(
          "Sem email",
          "O caso não possui email",
          "warning"
        );
        this.closeQuickAction();
      } else {
        this.fillTitle();
      }

      this.showSpinner = false;
    } else if (error) {
      this.messages = undefined;
      console.log(error);
      this.showSpinner = false;
      this.showNotification(
        "Erro",
        "Ocorreu um erro inesperado! Contacte um adiministrador",
        "error"
      );
      this.closeQuickAction();
    }
  }

  sortByDateDesc(data) {
    return data.sort(function (a, b) {
      var c = new Date(a.MessageDate);
      var d = new Date(b.MessageDate);
      return d - c;
    });
  }

  fillTitle() {
    for (let message of this.messages) {
      let messageDate = new Date(message.MessageDate);
      let fromAddress = message.FromName
        ? message.FromName
        : message.FromAddress;

      Object.assign(message, {
        title:
          fromAddress +
          " - " +
          messageDate.toLocaleDateString("pt-br") +
          " " +
          messageDate.toLocaleTimeString("pt-br")
      });
    }
  }

  navigateToContentDocument(event) {
    this[NavigationMixin.GenerateUrl]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.target.name,
        actionName: "view"
      }
    }).then((url) => {
      window.open(url);
    });
  }

  handleInfoClick() {
    this.openPopover = true;
  }

  handleCloseInfo() {
    this.openPopover = false;
  }

  showNotification(titulo, mensagem, variante) {
    const evt = new ShowToastEvent({
      title: titulo,
      message: mensagem,
      variant: variante,
      mode: "sticky"
    });
    this.dispatchEvent(evt);
  }

  closeQuickAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}
