import { LightningElement } from 'lwc';

export default class PagamentoPixError extends LightningElement {
    close(){
        this.dispatchEvent(new CustomEvent('close'));
    }
}