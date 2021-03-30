using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace PSFramework.Filter
{
    /// <summary>
    /// A set of conditions that can be applied to expressions.
    /// A filter expression can only contain conditions defined in the ConditionSet assigned.
    /// </summary>
    public class ConditionSet
    {
        /// <summary>
        /// Name of the condition set
        /// </summary>
        public string Name
        {
            get { return _Name; }
            set
            {
                if (!Regex.IsMatch(value, "^[\\d\\w_]+$"))
                    throw new PsfException("PSFramework.Assembly.Filter.InvalidName", null, value);
                _Name = value;
            }
        }
        private string _Name;

        /// <summary>
        /// The module defining the condition set
        /// </summary>
        public string Module;

        /// <summary>
        /// Version of the condition set.
        /// </summary>
        public Version Version;

        /// <summary>
        /// Returns the list of conditions included in the set.
        /// Mostly for display purposes.
        /// </summary>
        public List<Condition> Conditions
        {
            get
            {
                return new List<Condition>(ConditionTable.Values);
            }
        }

        /// <summary>
        /// The conditions contained within the condition set
        /// </summary>
        public Dictionary<string, Condition> ConditionTable = new Dictionary<string, Condition>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Create a new condition set
        /// </summary>
        /// <param name="Name">Name of the set</param>
        /// <param name="Module">Module under which the condition set is defined</param>
        /// <param name="Version">Version of the set</param>
        /// <param name="Conditions">Conditions to include in the set.</param>
        public ConditionSet(string Name, string Module, Version Version, List<Condition> Conditions)
        {
            this.Name = Name;
            this.Module = Module;
            this.Version = Version;
            if (Conditions != null)
                foreach (Condition condition in Conditions)
                    ConditionTable[condition.Name] = condition;
        }

        /// <summary>
        /// Default string representation.
        /// </summary>
        /// <returns>The name of the condition set</returns>
        public override string ToString()
        {
            return Name;
        }

        /// <summary>
        /// Add a condition object to the condition set.
        /// </summary>
        /// <param name="Condition">The condition object to add</param>
        public void Add(Condition Condition)
        {
            ConditionTable[Condition.Name] = Condition;
        }
    }
}
