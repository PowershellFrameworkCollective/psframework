using System;
using System.Collections.Generic;
using System.Management.Automation;

namespace PSFramework.TabExpansion
{
    /// <summary>
    /// Compares two completion results
    /// </summary>
    public class CompletionResultComparer : IComparer<CompletionResult>
    {
        /// <summary>
        /// Compares two completion results
        /// </summary>
        /// <param name="Completer1">Completer to compare</param>
        /// <param name="Completer2">Completer to compare</param>
        /// <returns>-1, 0 or 1</returns>
        public int Compare(CompletionResult Completer1, CompletionResult Completer2)
        {
            return Completer1.CompletionText.CompareTo(Completer2.CompletionText);
        }
    }
}
