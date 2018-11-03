using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Meta
{
    /// <summary>
    /// Information object for a command on the pipeline
    /// </summary>
    public class PipelineCommand
    {
        /// <summary>
        /// ID of the pipeline the command was read from
        /// </summary>
        public int PipelineId;

        /// <summary>
        /// Index of the command within the pipeline
        /// </summary>
        public int Index;

        /// <summary>
        /// Information on the command itself
        /// </summary>
        public CommandInfo Command;

        /// <summary>
        /// Under what name was the command called?
        /// </summary>
        public string InvocationName
        {
            get
            {
                if (InvocationInfo != null)
                    return InvocationInfo.InvocationName;
                return "";
            }
        }

        /// <summary>
        /// The full invocation information
        /// </summary>
        public InvocationInfo InvocationInfo;

        /// <summary>
        /// The parameters that were bound to the command
        /// </summary>
        public Dictionary<string, object> BoundParameters
        {
            get { return InvocationInfo.BoundParameters; }
        }

        /// <summary>
        /// The actual PowerShell internal object representing the command on the pipeline
        /// </summary>
        public object CommandItem;

        /// <summary>
        /// Tests whether the specified cmdlet variable is the same instance of its class as this one.
        /// </summary>
        /// <param name="CmdletItem">The cmdlet to compare</param>
        /// <returns>Whether the specified cmdlet is the same instance as this one</returns>
        public bool IsCommand(PSCmdlet CmdletItem)
        {
            return CmdletItem.MyInvocation == InvocationInfo;
        }

        /// <summary>
        /// Create a new pipelinecommand object
        /// </summary>
        /// <param name="PipelineId">ID of the pipeline the command was read from</param>
        /// <param name="Index">Index of the command within the pipeline</param>
        /// <param name="Command">Information on the command itself</param>
        /// <param name="InvocationInfo">The full invocation information</param>
        /// <param name="CommandItem">The actual PowerShell internal object representing the command on the pipeline</param>
        public PipelineCommand(int PipelineId, int Index, CommandInfo Command, InvocationInfo InvocationInfo, object CommandItem)
        {
            this.PipelineId = PipelineId;
            this.Index = Index;
            this.Command = Command;
            this.InvocationInfo = InvocationInfo;
            this.CommandItem = CommandItem;
        }
    }
}
