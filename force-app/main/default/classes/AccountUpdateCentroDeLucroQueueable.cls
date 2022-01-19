public class AccountUpdateCentroDeLucroQueueable implements Queueable {
    private Set<Id> setAccountId;

    public AccountUpdateCentroDeLucroQueueable(Set<Id> tempSetAccountId){
        this.setAccountId = tempSetAccountId;
    }

    public void execute(QueueableContext qc){
        Database.executeBatch(new AccountUpdateCentroDeLucroBatch(this.setAccountId));
        System.debug('batch started');
    }
}