using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Commands
{
    /// <summary>
    /// Amazingly useful command, that verifies that the command being executed was called from another command in the same module.
    /// </summary>
    [Cmdlet(VerbsLifecycle.Assert, "PSFInternalCommand")]
    public class AssertPSFInternalCommandCommand : PSFCmdlet
    {
        /// <summary>
        /// The $PSCmdlet variable of the calling function. This allows us to throw the error from the calling command and hide our cmdlet to the end user.
        /// </summary>
        [Parameter(Mandatory = true)]
        public PSCmdlet PSCmdlet { get; set; }

        /// <summary>
        /// The main implementation, doing the various checks needed to ensure it is only called internally.
        /// </summary>
        protected override void ProcessRecord()
        {
            CallStackFrame directCaller = GetCaller(0);
            CallStackFrame callerOfCaller = GetCaller(1);

            if (directCaller.InvocationInfo.MyCommand == null)
                Throw(ErrorCategory.InvalidOperation, "The command 'Assert-PSFInternalCommand' can only be called from within a function");

            if (null == directCaller.InvocationInfo.MyCommand.Module)
                Throw(ErrorCategory.InvalidOperation, "The command 'Assert-PSFInternalCommand' can only be called from a function that is part of a module!");

            if (null == callerOfCaller.InvocationInfo.MyCommand.Module)
                Throw(ErrorCategory.SecurityError, $"The command '{directCaller.FunctionName}' can only be called from another command that is also part of module '{directCaller.InvocationInfo.MyCommand.ModuleName}'");

            if (directCaller.InvocationInfo.MyCommand.Module != callerOfCaller.InvocationInfo.MyCommand.Module)
                Throw(ErrorCategory.SecurityError, $"The command '{directCaller.FunctionName}' can only be called from another command that is also part of module '{directCaller.InvocationInfo.MyCommand.ModuleName}'");
        }

        private void Throw(ErrorCategory Category,string Message)
        {
            Exception exception = new Exception(Message);
            switch (Category)
            {
                case ErrorCategory.InvalidOperation:
                    exception = new InvalidOperationException(Message);
                    break;
                case ErrorCategory.SecurityError:
                    exception = new PSSecurityException(Message);
                    break;
            }

            ErrorRecord record = new ErrorRecord(exception, "AssertionFailed", Category, null);
            PSCmdlet.ThrowTerminatingError(record);
        }
    }
}
