using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation.Language;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Meta
{
    /// <summary>
    /// Object representing a pipeline at runtime
    /// </summary>
    public class Pipeline
    {
        /// <summary>
        /// The unique ID of the pipeline
        /// </summary>
        public int InstanceId;

        /// <summary>
        /// When the pipeline was created
        /// </summary>
        public DateTime StartTime;

        /// <summary>
        /// The commands that make up the pipeline
        /// </summary>
        public List<PipelineCommand> Commands = new List<PipelineCommand>();

        /// <summary>
        /// The full text of the pipeline
        /// </summary>
        public string Text;

        /// <summary>
        /// The Ast of the pipeline
        /// </summary>
        public Ast Ast;

        /// <summary>
        /// Whether the output is getting assigned to something
        /// </summary>
        public bool OutputAssigned;

        /// <summary>
        /// What the output gets assigned to
        /// </summary>
        public string OutputAssignedTo;

        /// <summary>
        /// Does the pipeline receive input from a variable?
        /// </summary>
        public bool InputFromVariable;

        /// <summary>
        /// What variable does the pipeline receive input from
        /// </summary>
        public string InputVariable;

        /// <summary>
        /// Does the pipeline receive a constant as input value directly?
        /// </summary>
        public bool InputDirect;

        /// <summary>
        /// What is the value it receives?
        /// </summary>
        public object InputValue;

        /// <summary>
        /// The actual PowerShell internal pipeline object
        /// </summary>
        public object PipelineItem;
    }
}
