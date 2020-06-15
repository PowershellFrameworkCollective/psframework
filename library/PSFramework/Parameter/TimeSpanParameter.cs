using PSFramework.Utility;
using System;
using System.Globalization;
using System.Linq;
using System.Management.Automation;
using System.Text.RegularExpressions;

namespace PSFramework.Parameter
{
    /// <summary>
    /// Parameter class for interpreting timespans
    /// </summary>
    [ParameterClass]
    public class TimeSpanParameter : ParameterClass
    {
        #region Fields of contract
        /// <summary>
        /// The resolved timespan value
        /// </summary>
        [ParameterContract(ParameterContractType.Field, ParameterContractBehavior.Mandatory)]
        public TimeSpan Value;
        #endregion Fields of contract

        /// <summary>
        /// The string value of the timespan object contained within.
        /// </summary>
        /// <returns>The string value of the timespan object contained within.</returns>
        public override string ToString()
        {
            return Value.ToString();
        }

        #region Operators
        /// <summary>
        /// Implicitly converts the parameter to timespan, allowing it to be used on parameters requiring the type
        /// </summary>
        /// <param name="Parameter">The parameterclass object to convert</param>
        [ParameterContract(ParameterContractType.Operator, ParameterContractBehavior.Conversion)]
        public static implicit operator TimeSpan(TimeSpanParameter Parameter)
        {
            return Parameter.Value;
        }

        /// <summary>
        /// Implicitly converts a timespan to this parameterclass object.
        /// </summary>
        /// <param name="Value">The timespan object to convert</param>
        [ParameterContract(ParameterContractType.Operator, ParameterContractBehavior.Conversion)]
        public static implicit operator TimeSpanParameter(TimeSpan Value)
        {
            return new TimeSpanParameter(Value);
        }
        #endregion Operators
        
        #region Constructors
        /// <summary>
        /// Creates a TimeSpanParameter from a TimeSpan object (not the hardest challenge)
        /// </summary>
        /// <param name="Value">The timespan object to accept</param>
        public TimeSpanParameter(TimeSpan Value)
        {
            this.Value = Value;
            InputObject = Value;
        }

        /// <summary>
        /// Creates a TimeSpanParameter from integer, assuming it to mean seconds
        /// </summary>
        /// <param name="Seconds">The seconds to run</param>
        public TimeSpanParameter(int Seconds)
        {
            Value = new TimeSpan(0, 0, Seconds);
            InputObject = Seconds;
        }

        /// <summary>
        /// Creates a TimeSpanParameter from a string object
        /// </summary>
        /// <param name="Value">The string to interpret</param>
        public TimeSpanParameter(string Value)
        {
            this.Value = ParseTimeSpan(Value);
            InputObject = Value;
        }

        /// <summary>
        /// Creates a TimeSpanParameter from any kind of object it has been taught to understand
        /// </summary>
        /// <param name="InputObject">The object to interpret</param>
        public TimeSpanParameter(object InputObject)
        {
            if (InputObject == null)
                throw new ArgumentException("Input must not be null");

            PSObject input = new PSObject(InputObject);
            this.InputObject = InputObject;

            string key = "";

            foreach (string name in input.TypeNames)
            {
                if ((name == "Sqlcollaborative.Dbatools.Utility.DbaTimeSpanPretty") || (name == "Deserialized.Sqlcollaborative.Dbatools.Utility.DbaTimeSpanPretty"))
                {
                    Value = new TimeSpan((long)input.Properties["Ticks"].Value);
                    return;
                }
                if ((name == "Sqlcollaborative.Dbatools.Utility.DbaTimeSpan") || (name == "Deserialized.Sqlcollaborative.Dbatools.Utility.DbaTimeSpan"))
                {
                    Value = new TimeSpan((long)input.Properties["Ticks"].Value);
                    return;
                }

                if (_PropertyMapping.ContainsKey(name))
                {
                    key = name;
                    break;
                }
            }

            if (key == "")
                throw new ArgumentException(String.Format("Could not interpret {0}", InputObject.GetType().FullName));

            bool test = false;
            foreach (string property in _PropertyMapping[key])
            {
                if (input.Properties[property] != null && input.Properties[property].Value != null)
                {
                    try
                    {
                        Value = new TimeSpanParameter(input.Properties[property].Value);
                        test = true;
                        break;
                    }
                    catch { }
                }
            }

            if (!test)
                throw new ArgumentException(String.Format("Could not interpret {0} (<{1}>) as valid timespan", InputObject, InputObject.GetType().Name));
        }
        #endregion Constructors

        #region Helper Methods
        /// <summary>
        /// Parses an input string as timespan
        /// </summary>
        /// <param name="Value">The string to interpret</param>
        /// <returns>The interpreted timespan value</returns>
        internal static TimeSpan ParseTimeSpan(string Value)
        {
            if (String.IsNullOrWhiteSpace(Value))
                throw new ArgumentNullException("Cannot parse empty string!");

            try { return TimeSpan.Parse(Value, CultureInfo.CurrentCulture); }
            catch { }
            try { return TimeSpan.Parse(Value, CultureInfo.InvariantCulture); }
            catch { }

            bool positive = !(Value.Contains('-'));
            TimeSpan timeResult = new TimeSpan();
            string tempValue = Value.Replace("-", "").Trim();

            foreach (string element in tempValue.Split(' '))
            {
                if (Regex.IsMatch(element, @"^\d+$"))
                    timeResult = timeResult.Add(new TimeSpan(0, 0, Int32.Parse(element)));
                else if (UtilityHost.IsLike(element, "*ms") && Regex.IsMatch(element, @"^\d+ms$", RegexOptions.IgnoreCase))
                    timeResult = timeResult.Add(new TimeSpan(0, 0, 0, 0, Int32.Parse(Regex.Match(element, @"^(\d+)ms$", RegexOptions.IgnoreCase).Groups[1].Value)));
                else if (UtilityHost.IsLike(element, "*s") && Regex.IsMatch(element, @"^\d+s$", RegexOptions.IgnoreCase))
                    timeResult = timeResult.Add(new TimeSpan(0, 0, Int32.Parse(Regex.Match(element, @"^(\d+)s$", RegexOptions.IgnoreCase).Groups[1].Value)));
                else if (UtilityHost.IsLike(element, "*m") && Regex.IsMatch(element, @"^\d+m$", RegexOptions.IgnoreCase))
                    timeResult = timeResult.Add(new TimeSpan(0, Int32.Parse(Regex.Match(element, @"^(\d+)m$", RegexOptions.IgnoreCase).Groups[1].Value), 0));
                else if (UtilityHost.IsLike(element, "*h") && Regex.IsMatch(element, @"^\d+h$", RegexOptions.IgnoreCase))
                    timeResult = timeResult.Add(new TimeSpan(Int32.Parse(Regex.Match(element, @"^(\d+)h$", RegexOptions.IgnoreCase).Groups[1].Value), 0, 0));
                else if (UtilityHost.IsLike(element, "*d") && Regex.IsMatch(element, @"^\d+d$", RegexOptions.IgnoreCase))
                    timeResult = timeResult.Add(new TimeSpan(Int32.Parse(Regex.Match(element, @"^(\d+)d$", RegexOptions.IgnoreCase).Groups[1].Value), 0, 0, 0));
                else
                    throw new ArgumentException(String.Format("Failed to parse as timespan: {0} at {1}", Value, element));
            }

            if (!positive)
                return timeResult.Negate();
            return timeResult;
        }
        #endregion Helper Methods
    }
}
