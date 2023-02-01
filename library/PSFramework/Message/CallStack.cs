using System;
using System.Collections.Generic;
using System.Management.Automation;

namespace PSFramework.Message
{
    /// <summary>
    /// Container for a callstack, to create a non-volatile copy of the relevant information
    /// </summary>
    [Serializable]
    public class CallStack
    {
        /// <summary>
        /// The entries that make up the callstack
        /// </summary>
        public List<CallStackEntry> Entries = new List<CallStackEntry>();

        /// <summary>
        /// The string sequence used to join callstack entries by default.
        /// </summary>
        public string DefaultEntryJoinSequence = "\n\t";

        /// <summary>
        /// String representation of the callstack copy
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            return String.Join(DefaultEntryJoinSequence, Entries);
        }

        /// <summary>
        /// String representation of the callstack copy
        /// </summary>
        /// <param name="JoinBy">By what the individual lines should be joined</param>
        /// <returns></returns>
        public string ToString(string JoinBy)
        {
            return String.Join(JoinBy, Entries);
        }

        /// <summary>
        /// Picks a subset of the total callstack
        /// </summary>
        /// <param name="Start">The starting index to work from. Anything larger than 0 means skipping the innermost entries of the stack.</param>
        /// <returns>A pared-down callstack</returns>
        /// <exception cref="IndexOutOfRangeException">When the starting index is larger than the number of entries available.</exception>
        public CallStack GetSubStack(int Start)
        {
            if (Start >= Entries.Count)
                throw new IndexOutOfRangeException($"Cannot specify a starting position ({ Start }) larger than the total count ({ Entries.Count }) minus one!");

            int count = Entries.Count - Start;
            return GetSubStack(Start, count);
        }

        /// <summary>
        /// Picks a subset of the total callstack
        /// </summary>
        /// <param name="Start">The starting index to work from. Anything larger than 0 means skipping the innermost entries of the stack.</param>
        /// <param name="Count">How many entries should be included after the start index.</param>
        /// <returns>A pared-down callstack</returns>
        /// <exception cref="IndexOutOfRangeException">When the starting index is larger than the number of entries available.</exception>
        public CallStack GetSubStack(int Start, int Count)
        {
            if (Start >= Entries.Count)
                throw new IndexOutOfRangeException($"Cannot specify a starting position ({ Start }) larger than the total count ({ Entries.Count }) minus one!");

            if (Start + Count > Entries.Count)
                Count = Entries.Count - Start;

            CallStack stack = new CallStack();
            CallStackEntry[] entryArray = new CallStackEntry[Count];
            Entries.CopyTo(Start, entryArray, 0, Count);
            stack.Entries.AddRange(entryArray);
            return stack;
        }

        /// <summary>
        /// Create an empty callstack
        /// </summary>
        public CallStack()
        {
            
        }

        /// <summary>
        /// Initialize a callstack from a live callstack frame
        /// </summary>
        /// <param name="CallStack">The live powershell callstack</param>
        public CallStack(IEnumerable<CallStackFrame> CallStack)
        {
            foreach (CallStackFrame frame in CallStack)
                Entries.Add(new CallStackEntry(frame.FunctionName, frame.ScriptName, frame.ScriptLineNumber, frame.InvocationInfo));
        }
    }
}
