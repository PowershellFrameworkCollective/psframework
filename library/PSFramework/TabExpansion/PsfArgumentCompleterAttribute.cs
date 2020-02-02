using System;
using System.Management.Automation;

namespace PSFramework.TabExpansion
{
    /// <summary>
    /// Allows integrating PSFramework tab expansion by attribute, rather than command.
    /// </summary>
    public class PsfArgumentCompleterAttribute : ArgumentCompleterAttribute
    {
        /// <summary>
        /// Create an argument completer offering but the name of the registered completion
        /// </summary>
        /// <param name="Completion">The completion scriptblock to use to provide completion information</param>
        public PsfArgumentCompleterAttribute(string Completion)
            : base(TabExpansionHost.Scripts.ContainsKey(Completion) ? TabExpansionHost.Scripts[Completion].ScriptBlock : ScriptBlock.Create(""))
        {
            
        }

        /// <summary>
        /// Create an argument completer offering a scriptblock that is supposed to produce completion data.
        /// </summary>
        /// <param name="ScriptBlock">The scriptblock to use for completion data generation</param>
        public PsfArgumentCompleterAttribute(ScriptBlock ScriptBlock)
            : base(TabExpansionHost.RegisterCompletion(Guid.NewGuid().ToString(), ScriptBlock, TeppScriptMode.Auto, new Parameter.TimeSpanParameter(0), true).ScriptBlock)
        {

        }

        /// <summary>
        /// Create an argument completer offering a scriptblock that is supposed to produce completion data.
        /// </summary>
        /// <param name="ScriptBlock">The scriptblock to use for completion data generation</param>
        /// <param name="Name">The name to assign to this completion. Must be unique per scriptblock</param>
        public PsfArgumentCompleterAttribute(ScriptBlock ScriptBlock, string Name)
            : base(TabExpansionHost.RegisterCompletion(Name, ScriptBlock, TeppScriptMode.Auto, new Parameter.TimeSpanParameter(0), true).ScriptBlock)
        {

        }
    }
}
