using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Information for a specific runspace of a worker.
    /// </summary>
    public class RSWorkflowRunespaceReport
    {
        /// <summary>
        /// The overall workflow this belongs to
        /// </summary>
        public readonly RSWorkflow Workflow;
        /// <summary>
        /// The worker that manages the runspace
        /// </summary>
        public readonly RSWorker Worker;
        /// <summary>
        /// ID of the runspace
        /// </summary>
        public int Id => Runspace.Id;
        /// <summary>
        /// Current state of the runspace. Should always be busy until the worker closes down.
        /// </summary>
        public RunspaceAvailability State => Runspace.RunspaceAvailability;
        /// <summary>
        /// Name of the runspace. Should be "PSF-&lt;workflow&gt;-&lt;worker&gt;-&lt;index&gt;
        /// </summary>
        public string Name => Runspace.Name;
        /// <summary>
        /// PowerShell runspace executing the actual code of the worker
        /// </summary>
        public readonly System.Management.Automation.Runspaces.Runspace Runspace;

        internal RSWorkflowRunespaceReport(RSWorkflow workflow, RSWorker worker, System.Management.Automation.Runspaces.Runspace runspace)
        {
            Workflow = workflow;
            Worker = worker;
            Runspace = runspace;
        }
    }
}
