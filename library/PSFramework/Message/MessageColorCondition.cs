using PSFramework.Commands;
using System;
using System.Linq;

namespace PSFramework.Message
{
    /// <summary>
    /// A rule object to change the default color of a message written to screen.
    /// </summary>
    public class MessageColorCondition
    {
        /// <summary>
        /// Name of the condition, making it easier to manage rules and figure out where a rule comes form
        /// </summary>
        public string Name;

        /// <summary>
        /// The color it applies to
        /// </summary>
        public ConsoleColor Color;

        /// <summary>
        /// The precedence weight. The lower the number the higher the priority. The first match wins.
        /// </summary>
        public int Priority = 50;

        /// <summary>
        /// Minimum message level
        /// </summary>
        public int MinLevel = -1;

        /// <summary>
        /// Maximum message level
        /// </summary>
        public int MaxLevel = -1;

        /// <summary>
        /// At least one specified tag must be included
        /// </summary>
        public string[] IncludeTags;

        /// <summary>
        /// Any one of these tags disqualifies
        /// </summary>
        public string[] ExcludeTags;

        /// <summary>
        /// Any one of these modules must be included
        /// </summary>
        public string[] IncludeModules;

        /// <summary>
        /// Any one of these modules disqualify
        /// </summary>
        public string[] ExcludeModules;

        /// <summary>
        /// Any one of these functions must be included
        /// </summary>
        public string[] IncludeFunctions;

        /// <summary>
        /// Any one of these functions disqualify
        /// </summary>
        public string[] ExcludeFunctions;

        /// <summary>
        /// Create a new Message Color Condition
        /// </summary>
        /// <param name="Name">The name of the condition. Not case sensitive.</param>
        /// <param name="Color">The color this rule applies</param>
        /// <exception cref="ArgumentNullException">Providing an empty string for a name will not end well.</exception>
        public MessageColorCondition(string Name, ConsoleColor Color)
        {
            if (String.IsNullOrEmpty(Name))
                throw new ArgumentNullException("Name");

            this.Name = Name;
            this.Color = Color;
        }

        /// <summary>
        /// Whether the specified message color condition applies to the current message
        /// </summary>
        /// <param name="Command">The Write-PSFMessage command currently being processed</param>
        /// <returns>Whether the message applies</returns>
        internal bool Applies(WritePSFMessageCommand Command)
        {
            if (MinLevel >= 0 && (int)Command.Level < MinLevel)
                return false;
            if (MaxLevel >= 0 && (int)Command.Level > MaxLevel)
                return false;

            if (HasOverlap(ExcludeTags, Command.Tag))
                return false;
            if (HasOverlap(ExcludeFunctions, Command.FunctionName))
                return false;
            if (HasOverlap(ExcludeModules, Command.ModuleName))
                return false;

            if (IncludeTags != null && !HasOverlap(IncludeTags, Command.Tag))
                return false;
            if (IncludeFunctions != null && !HasOverlap(IncludeFunctions, Command.FunctionName))
                return false;
            if (IncludeModules != null && !HasOverlap(IncludeModules, Command.ModuleName))
                return false;

            return true;
        }

        /// <summary>
        /// Helper utility, comparing two string arrays and checking whether at least one value is in both.
        /// Is not case sensitive.
        /// </summary>
        /// <param name="One">The first array to compare</param>
        /// <param name="Two">The second array to compare</param>
        /// <returns>Whether at least one value is in both arrays</returns>
        private bool HasOverlap(string[] One, string[] Two)
        {
            if (One == null || One.Length == 0)
                return false;
            if (Two == null || Two.Length == 0)
                return false;

            foreach (string value in One)
                if (Two.Contains(value, StringComparer.InvariantCultureIgnoreCase))
                    return true;

            return false;
        }

        private bool HasOverlap(string[] One, string Two)
        {
            return HasOverlap(One, new string[] { Two });
        }
    }
}