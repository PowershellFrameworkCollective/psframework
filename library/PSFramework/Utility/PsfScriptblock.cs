﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Text;
using System.Threading.Tasks;
using PSFramework.Extension;
using PSFramework.Runspace;
using PSFramework.Utility;

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
            ScriptBlock tempScriptBlock = ScriptBlock;
            if (ImportContext)
                tempScriptBlock = ScriptBlock.Clone().Import(ImportGlobal);
            object result = tempScriptBlock.DoInvokeReturnAsIs(UseLocalScope, 2, DollerUnder, Input, ScriptThis, Args);
            if (result == null)
                return null;
            if (result.GetType() == typeof(PSObject))
                return new System.Collections.ObjectModel.Collection<PSObject>() { result as PSObject };
            return (System.Collections.ObjectModel.Collection<PSObject>)result;
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
        /// Invoke the Scriptblock rehomed to the current sessionstate
        /// </summary>
        /// <param name="Value">The value - if any - to offer as argument / input for the scriptblock</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public System.Collections.ObjectModel.Collection<PSObject> InvokeLocal(object Value = null)
        {
            return InvokeEx(true, Value, Value, null, true, false, Value);
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
        
        /// <summary>
        /// Return a global clone of the scriptblock
        /// </summary>
        /// <returns>A global clone of the scriptblock</returns>
        public ScriptBlock ToGlobal()
        {
            return ScriptBlock.Clone().ToGlobal();
        }
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
        /// Create a new PsfScriptBlock by wrapping a regular scriptblock.
        /// </summary>
        /// <param name="Script">The Scriptblock to wrap</param>
        /// <param name="Unwrap">Whether to unwrap a scriptblock. When a scriptblock only contains a scriptblock (as happens when importing from psd1), this causes the class to use the inner scriptblock.</param>
        public PsfScriptBlock(ScriptBlock Script, bool Unwrap)
        {
            if (Script == null)
                throw new ArgumentNullException("Script");

            ScriptBlockAst ast = (ScriptBlockAst)Script.Ast;
            if (
                !Unwrap ||
                ast.ParamBlock != null ||
                ast.BeginBlock != null ||
                ast.ProcessBlock != null ||
                ast.EndBlock.Statements.Count > 1 ||
                ast.EndBlock.Statements[0].GetType() != typeof(PipelineAst) ||
                ((PipelineAst)ast.EndBlock.Statements[0]).PipelineElements.Count > 1 ||
                ((PipelineAst)ast.EndBlock.Statements[0]).PipelineElements[0].GetType() != typeof(CommandExpressionAst) ||
                ((CommandExpressionAst)((PipelineAst)ast.EndBlock.Statements[0]).PipelineElements[0]).Expression.GetType() != typeof(ScriptBlockExpressionAst)
            )
            {
                ScriptBlock = Script;
                return;
            }

            ScriptBlock = LanguagePrimitives.ConvertTo<ScriptBlock>(Script.Invoke()[0]);
            UtilityHost.SetPrivateProperty("LanguageMode", ScriptBlock, (new PsfScriptBlock(Script)).LanguageMode);
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
