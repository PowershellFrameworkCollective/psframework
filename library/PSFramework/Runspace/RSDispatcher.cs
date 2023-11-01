using PSFramework.Utility;
using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Runspace worker dispatcher. Central piece tying together runspace execution and data exchange.
    /// </summary>
    public class RSDispatcher
    {
        /// <summary>
        /// The name of the dispatcher. Pure documentation.
        /// </summary>
        public string Name;

        /// <summary>
        /// The count of workers registered to this dispatcher
        /// </summary>
        public int WorkerCount => Workers.Count;

        /// <summary>
        /// The names of the workers registered to this dispatcher
        /// </summary>
        public string[] WorkerNames => Workers.Values.Select(o => o.Name).ToArray();

        /// <summary>
        /// The queues in this dispatcher
        /// </summary>
        public string[] QueueNames => Queues.Keys.Select(o => $"{o} ({Queues[o].Count})").ToArray();

        /// <summary>
        /// The queues used for data exchange. Queues are created on demand.
        /// </summary>
        public RSQueueManager Queues = new RSQueueManager();

        /// <summary>
        /// Additional data exchange available to all workers.
        /// </summary>
        public ConcurrentDictionary<string, object> Data = new ConcurrentDictionary<string, object>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Workers associated with this dispatcher.
        /// </summary>
        public ConcurrentDictionary<string, RSWorker> Workers = new ConcurrentDictionary<string, RSWorker>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Provide a default session state for all workers.
        /// </summary>
        public InitialSessionState SessionState;

        /// <summary>
        /// Any variables to include in the worker runspaces.
        /// </summary>
        public Hashtable Variables = new Hashtable();

        /// <summary>
        /// Modules to include in the worker runspaces. Always includes the PSFramework.
        /// </summary>
        public List<string> Modules = new List<string>();

        /// <summary>
        /// Functions to inject into the worker runspaces.
        /// </summary>
        public Dictionary<string, ScriptBlock> Functions = new Dictionary<string, ScriptBlock>();

        /// <summary>
        /// Create a new runsoace dispatcher, giving it a name for heck's sake.
        /// </summary>
        /// <param name="Name">The name of the dispatcher</param>
        public RSDispatcher(string Name)
        {
            this.Name = Name;
        }

        /// <summary>
        /// Close a data queue associated with the dispatcher.
        /// By doing so, all new entries will be prevented, effectively soft-killing the processing.
        /// </summary>
        /// <param name="Name">The name of the queue to close</param>
        public void CloseQueue(string Name)
        {
            Queues[Name].Closed = true;
        }

        /// <summary>
        /// Add a new worker to the dispatcher.
        /// </summary>
        /// <param name="Name">The name of the worker. Used to differentiate workers from each other</param>
        /// <param name="InQueue">Name of the inqueue to use.</param>
        /// <param name="OutQueue">Name of the outqueue to use.</param>
        /// <param name="ScriptBlock">The scriptblock that will process each input item from the inqueue and produce the ouptut to the outqueue. Receives one input item and all output will be handled.</param>
        /// <param name="Count">The number of worker runspaces to create.</param>
        /// <returns>The created worker object.</returns>
        public RSWorker AddWorker(string Name, string InQueue, string OutQueue, PsfScriptBlock ScriptBlock, int Count = 1)
        {
            RSWorker worker = new RSWorker(Name, InQueue, OutQueue, ScriptBlock, this, Count);
            Workers[Name] = worker;
            return worker;
        }

        /// <summary>
        /// Launch all workers of this dispatcher
        /// </summary>
        public void Start()
        {
            foreach (RSWorker worker in Workers.Values)
                worker.Start();
        }

        /// <summary>
        /// Stop all workers of this dispatcher. Workers will gracefully finish their current item to process and execute any closing logic before terminating.
        /// </summary>
        public void Stop()
        {
            foreach (RSWorker worker in Workers.Values)
                worker.Stop();
        }
    }
}
