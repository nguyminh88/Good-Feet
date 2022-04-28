/* Developed by Minh Nguyen
 * 
 * Triage class to enqueue midwest customer accounts to Acumatica.  
 * Only used during interim, until Midwest can get off of Acumatica.  
*/
public class AcumaticaEnqueuer {
    
    public static void Enqueue(list<account> accList){
        if(!accList.isEmpty()){ 
            AcumaticaAccQueueable ACU = new AcumaticaAccQueueable(acclist);
            system.enqueueJob(ACU);
        }
    }

}