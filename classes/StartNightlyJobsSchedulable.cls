public class StartNightlyJobsSchedulable implements Schedulable, Database.AllowsCallouts{
	public void execute(SchedulableContext ctx){
        Database.executeBatch(new MWStagingProcessingBatch(), 1);
    }
}