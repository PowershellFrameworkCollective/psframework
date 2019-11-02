using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

using PSFramework.Meta;
using PSFramework.Utility;

namespace PSFramework.FlowControl
{
    /// <summary>
    /// Data structure representing a registered callback scriptblock
    /// </summary>
    public class Callback
    {
        /// <summary>
        /// The name of the callback script. Used to build the unique ID to prevent accidental duplication
        /// </summary>
        public string Name;

        /// <summary>
        /// Name of the module the callback applies to. Only when invoked from within this module will it trigger
        /// </summary>
        public string ModuleName;

        /// <summary>
        /// Name of the command the callback applies to. Only when invoked from a command with a similar name will it trigger
        /// </summary>
        public string CommandName;

        /// <summary>
        /// The runspace the callback belongs to. If this is set, only when invoked from that runspace will it trigger.
        /// </summary>
        public Nullable<Guid> Runspace;

        /// <summary>
        /// Whether the scriptblock's runspace affinity should be broken. Setting this to true will execute the scriptblock in the runspace that triggered it, rather than the one that defined it.
        /// </summary>
        public bool BreakAffinity;

        /// <summary>
        /// The actual callback scriptcode
        /// </summary>
        public ScriptBlock ScriptBlock;

        /// <summary>
        /// The full identity of the callback. Used for internal callback management.
        /// </summary>
        internal string Identity
        {
            get { return String.Format("{0}|{1}", Runspace, Name); }
        }

        /// <summary>
        /// Whether the callback applies to the current command.
        /// </summary>
        /// <param name="ModuleName">Module the current command is part of</param>
        /// <param name="CommandName">Command that is currently executing</param>
        /// <returns>True if it applies, otherwise False</returns>
        public bool Applies(string ModuleName, string CommandName)
        {
            if (!ModuleName.Equals(ModuleName, StringComparison.InvariantCultureIgnoreCase))
                return false;
            if ((Runspace != null) & (Runspace != System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId))
                return false;
            if (!UtilityHost.IsLike(CommandName, this.CommandName))
                return false;
            return true;
        }

        /// <summary>
        /// Invokes the callback scriptblock as configured.
        /// </summary>
        /// <param name="Caller">The object containing the information pertaining to the calling command.</param>
        /// <param name="Invoker">The meta object representing the invoking command.</param>
        /// <param name="Data">Extra data that was passed to the event</param>
        public void Invoke(CallerInfo Caller, PSCmdlet Invoker, object Data)
        {
            Hashtable table = new Hashtable(StringComparer.InvariantCultureIgnoreCase);
            table["Command"] = Invoker.MyInvocation.MyCommand.Name;
            table["ModuleName"] = Invoker.MyInvocation.MyCommand.ModuleName;
            table["CallerFunction"] = Caller.CallerFunction;
            table["CallerModule"] = Caller.CallerModule;
            table["Data"] = Data;

            try
            {
                if (BreakAffinity)
                {
                    lock (_InvokeLock)
                    {
                        UtilityHost.ImportScriptBlock(ScriptBlock);
                        ScriptBlock.Invoke(table);
                    }
                }
                else
                    ScriptBlock.Invoke(table);
            }
            catch (Exception e)
            {
                throw new CallbackException(this, e);
            }
        }
        private object _InvokeLock = 42;

        /// <summary>
        /// Returns the string representation of the callback
        /// </summary>
        /// <returns>The string representation of the callback</returns>
        public override string ToString()
        {
            return Name;
        }
    }
}
