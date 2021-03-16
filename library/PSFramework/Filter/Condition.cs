using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace PSFramework.Filter
{
    /// <summary>
    /// An individual filter condition.
    /// Building block of a PSFramework filter expression.
    /// </summary>
    public class Condition
    {
        /// <summary>
        /// Name of the condition. The String used within the expression.
        /// </summary>
        public string Name
        {
            get { return _Name; }
            set
            {
                if (!Regex.IsMatch(value, "^[\\d\\w_]+$"))
                    throw new PsfException("PSFramework.Assembly.Filter.InvalidName", null, value);
                if (value == "0" || value == "1")
                    throw new PsfException("PSFramework.Assembly.Filter.InvalidName", null, value);
                _Name = value;
            }
        }
        private string _Name;
        
        /// <summary>
        /// Name of the module owning the condition.
        /// </summary>
        public string Module;

        /// <summary>
        /// Version of the condition. Multiple versions can coexist.
        /// </summary>
        public Version Version;

        /// <summary>
        /// The actual script-code that is run when evaluating this condition
        /// </summary>
        public PsfScriptBlock ScriptBlock;

        /// <summary>
        /// What kind of condition is this?
        /// Static conditions are evaluated once only and are generally used for environment-conditions that are unlikely to change at runtime (e.g.: Operating System, PowerShell Version, runtime environment).
        /// Dynamic conditions are evaluated each time they are invoked.
        /// </summary>
        public ConditionType Type = ConditionType.Dynamic;

        /// <summary>
        /// Create a new condition.
        /// </summary>
        /// <param name="Name">Name of the condition</param>
        /// <param name="Module">Name of the module owning the condition</param>
        /// <param name="ScriptBlock">The scriptblock that evaluates the condition</param>
        /// <param name="Version">The version of the condition</param>
        /// <param name="Type">The type of the condition</param>
        public Condition(string Name, string Module, PsfScriptBlock ScriptBlock, Version Version, ConditionType Type = ConditionType.Dynamic)
        {
            this.Name = Name;
            this.Module = Module;
            this.ScriptBlock = ScriptBlock;
            this.Version = Version;
            this.Type = Type;
        }

        private bool _HasRun;
        private bool _LastResult;

        /// <summary>
        /// Evaluate the condition.
        /// This will run the stored scriptblock unless it is a static condition and has previously been invoked.
        /// </summary>
        /// <param name="Argument">An argument to pass to the scriptblock, available inside as $_</param>
        /// <returns>Whether the condition is met or not.</returns>
        public bool Invoke(object Argument = null)
        {
            if (_HasRun && Type == ConditionType.Static)
                return _LastResult;

            try
            {
                if (Argument != null && Type != ConditionType.Static)
                    _LastResult = LanguagePrimitives.IsTrue(ScriptBlock.InvokeEx(true, Argument, null, null, false, false, null));
                else
                    _LastResult = LanguagePrimitives.IsTrue(ScriptBlock.InvokeEx(true, null, null, null, false, false, null));
            }
            catch { throw; }

            _HasRun = true;
            return _LastResult;
        }

        /// <summary>
        /// Simple string representation of the condition
        /// </summary>
        /// <returns>The name of the condition</returns>
        public override string ToString()
        {
            return Name;
        }
    }
}
