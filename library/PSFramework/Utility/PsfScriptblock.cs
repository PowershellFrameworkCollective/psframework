using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;
using PSFramework.Extension;

namespace PSFramework.Utility
{
    /// <summary>
    /// Wrapper class around the traditional scriptblock class, extending its capabilities
    /// </summary>
    public class PsfScriptBlock
    {
        /// <summary>
        /// The original Scriptblock
        /// </summary>
        internal ScriptBlock ScriptBlock;

        #region Properties
        /// <summary>
        /// The language mode the scriptblock is running under
        /// </summary>
        public PSLanguageMode LanguageMode
        {
            get { return (PSLanguageMode)UtilityHost.GetPrivateProperty("LanguageMode", ScriptBlock); }
        }

        /// <summary>
        /// The Ast of he scriptblock
        /// </summary>
        public System.Management.Automation.Language.Ast Ast { get { return ScriptBlock.Ast; } }
        /// <summary>
        /// The Attributes that have been assigned to the scriptblock
        /// </summary>
        public List<Attribute> Attributes { get { return ScriptBlock.Attributes; } }
        /// <summary>
        /// Whether the scriptblock is visible to the debugger
        /// </summary>
        public bool DebuggerHidden
        {
            get { return ScriptBlock.DebuggerHidden; }
            set { ScriptBlock.DebuggerHidden = value; }
        }
        /// <summary>
        /// What file the scriptblock comes from
        /// </summary>
        public string File { get { return ScriptBlock.File; } }
        /// <summary>
        /// Unique ID of the scriptblock
        /// </summary>
        public Guid Id { get { return ScriptBlock.Id; } }
        /// <summary>
        /// Whether the scriptblock is a DSC configuration
        /// </summary>
        public bool IsConfiguration { get { return ScriptBlock.IsConfiguration; } }
        /// <summary>
        /// Whether the scriptblock is a filter
        /// </summary>
        public bool IsFilter { get { return ScriptBlock.IsFilter; } }
        /// <summary>
        /// The module the scriptblock belongs to.
        /// Don't rely on this, as it may be subject to change.
        /// </summary>
        public PSModuleInfo Module { get { return ScriptBlock.Module; } }
        /// <summary>
        /// Some text metadata of the scriptblock
        /// </summary>
        public PSToken StartPosition { get { return ScriptBlock.StartPosition; } }
        #endregion Properties

        #region Methods
        /// <summary>
        /// Returns the string representation of the scriptblock
        /// </summary>
        /// <returns>the string representation of the scriptblock</returns>
        public override string ToString()
        {
            return ScriptBlock.ToString();
        }

        /// <summary>
        /// Wraps the original Scriptblock method GetNewClosure()
        /// </summary>
        /// <returns>A copy of the ScriptBlock with a new closure.</returns>
        public ScriptBlock GetNewClosure()
        {
            return ScriptBlock.GetNewClosure();
        }

        /// <summary>
        /// Do a rich invocation of the scriptblock
        /// </summary>
        /// <param name="UseLocalScope">Whether a new scope should be created for this</param>
        /// <param name="DollerUnder">The value to make available as $_</param>
        /// <param name="Input">The value to make available to $input</param>
        /// <param name="ScriptThis">The value to make available as $this</param>
        /// <param name="ImportContext">Whether to first import the scriptblock into the current Context.</param>
        /// <param name="ImportGlobal">When importing the ScriptBlock, import it into the global Context instead.</param>
        /// <param name="Args">The value to make available as $args</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public System.Collections.ObjectModel.Collection<PSObject> InvokeEx(bool UseLocalScope, object DollerUnder, object Input, object ScriptThis, bool ImportContext, bool ImportGlobal, params object[] Args)
        {
            // Avoid concurrent access to prevent accidental Context import collisions when called in parallel from multiple runspaces.
            lock (_Lock)
            {
                if (ImportContext)
                    UtilityHost.ImportScriptBlock(ScriptBlock, ImportGlobal);
                object result = ScriptBlock.DoInvokeReturnAsIs(UseLocalScope, 2, DollerUnder, Input, ScriptThis, Args);
                if (result == null)
                    return null;
                if (result.GetType() == typeof(PSObject))
                    return new System.Collections.ObjectModel.Collection<PSObject>() { result as PSObject };
                return (System.Collections.ObjectModel.Collection<PSObject>)result;
            }
        }

        /// <summary>
        /// Do a rich invocation of the scriptblock
        /// </summary>
        /// <param name="UseLocalScope">Whether a new scope should be created for this</param>
        /// <param name="ImportContext">Whether to first import the scriptblock into the current Context.</param>
        /// <param name="ImportGlobal">When importing the ScriptBlock, import it into the global Context instead.</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public System.Collections.ObjectModel.Collection<PSObject> InvokeEx(bool UseLocalScope, bool ImportContext, bool ImportGlobal)
        {
            return InvokeEx(UseLocalScope, null, null, null, ImportContext, ImportGlobal, null);
        }

        /// <summary>
        /// Do a rich invocation of the scriptblock
        /// </summary>
        /// <param name="Value">The value to offer as argument / input for the scriptblock</param>
        /// <param name="UseLocalScope">Whether a new scope should be created for this</param>
        /// <param name="ImportContext">Whether to first import the scriptblock into the current Context.</param>
        /// <param name="ImportGlobal">When importing the ScriptBlock, import it into the global Context instead.</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public System.Collections.ObjectModel.Collection<PSObject> InvokeEx(object Value, bool UseLocalScope, bool ImportContext, bool ImportGlobal)
        {
            return InvokeEx(UseLocalScope, Value, Value, null, ImportContext, ImportGlobal, Value);
        }

        /// <summary>
        /// Invoke the Scriptblock rehomed to the global scope
        /// </summary>
        /// <param name="Value">The value - if any - to offer as argument / input for the scriptblock</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public System.Collections.ObjectModel.Collection<PSObject> InvokeGlobal(object Value = null)
        {
            return InvokeEx(true, Value, Value, null, true, true, Value);
        }

        /// <summary>
        /// Invoke the scriptblock in legacy mode.
        /// </summary>
        /// <param name="args">Arguments to pass into the scriptblock</param>
        /// <returns>The results of the invocation</returns>
        public System.Collections.ObjectModel.Collection<PSObject> Invoke(params object[] args)
        {
            return ScriptBlock.Invoke(args);
        }

        #pragma warning disable 0649
        private static PsfScriptBlock _Lock = ScriptBlock.Create("");
        #pragma warning restore 0649
        #endregion Methods

        /// <summary>
        /// Create a new PsfScriptBlock by wrapping a regular scriptblock.
        /// </summary>
        /// <param name="Script">The Scriptblock to wrap</param>
        public PsfScriptBlock(ScriptBlock Script)
        {
            ScriptBlock = Script;
        }

        /// <summary>
        /// Implicitly convert PsfScriptblock to ScriptBlock
        /// </summary>
        /// <param name="Script">The PsfScriptBlock to convert</param>
        public static implicit operator ScriptBlock(PsfScriptBlock Script)
        {
            return Script.ScriptBlock;
        }

        /// <summary>
        /// Implicitly convert ScriptBlock to PsfScriptblock
        /// </summary>
        /// <param name="Script">The ScriptBlock to convert</param>
        public static implicit operator PsfScriptBlock(ScriptBlock Script)
        {
            return new PsfScriptBlock(Script);
        }
    }
}
