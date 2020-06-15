using PSFramework.Utility;
using System;
using System.Collections.Generic;
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
    public class DateTimeParameter : ParameterClass
    {
        #region Fields of contract
        /// <summary>
        /// The resolved datetime value
        /// </summary>
        [ParameterContract(ParameterContractType.Field, ParameterContractBehavior.Mandatory)]
        public DateTime Value;
        #endregion Fields of contract

        /// <summary>
        /// The string value of the datetime object contained within.
        /// </summary>
        /// <returns>The string value of the datetime object contained within.</returns>
        public override string ToString()
        {
            return Value.ToString();
        }

        #region Operators
        /// <summary>
        /// Implicitly converts the parameter to datetime, allowing it to be used on parameters requiring the type
        /// </summary>
        /// <param name="Parameter">The parameterclass object to convert</param>
        [ParameterContract(ParameterContractType.Operator, ParameterContractBehavior.Conversion)]
        public static implicit operator DateTime(DateTimeParameter Parameter)
        {
            return Parameter.Value;
        }

        /// <summary>
        /// Implicitly converts a datetime to this parameterclass object.
        /// </summary>
        /// <param name="Value">The timespan object to convert</param>
        [ParameterContract(ParameterContractType.Operator, ParameterContractBehavior.Conversion)]
        public static implicit operator DateTimeParameter(DateTime Value)
        {
            return new DateTimeParameter(Value);
        }
        #endregion Operators

        #region Constructors
        /// <summary>
        /// Creates a DateTimeParameter from a DateTime object (not the hardest challenge)
        /// </summary>
        /// <param name="Value">The timespan object to accept</param>
        public DateTimeParameter(DateTime Value)
        {
            this.Value = Value;
            InputObject = Value;
        }

        /// <summary>
        /// Creates a DateTimeParameter with a DateTime value in seconds relative to the specifiewd number.
        /// </summary>
        /// <param name="Seconds">The seconds to differ from the current time.</param>
        public DateTimeParameter(int Seconds)
        {
            InputObject = Seconds;
            Value = DateTime.Now.AddSeconds(Seconds);
        }

        /// <summary>
        /// Creates a TimeSpanParameter from a string object
        /// </summary>
        /// <param name="Value">The string to interpret</param>
        public DateTimeParameter(string Value)
        {
            this.Value = ParseDateTime(Value);
            InputObject = Value;
        }

        /// <summary>
        /// Creates a TimeSpanParameter from any kind of object it has been taught to understand
        /// </summary>
        /// <param name="InputObject">The object to interpret</param>
        public DateTimeParameter(object InputObject)
        {
            if (InputObject == null)
                throw new ArgumentException("Input must not be null");

            PSObject input = new PSObject(InputObject);
            this.InputObject = InputObject;

            List<string> mappings = null;

            foreach (string name in input.TypeNames)
            {
                if ((name == "Sqlcollaborative.Dbatools.Utility.DbaDate") || (name == "Deserialized.Sqlcollaborative.Dbatools.Utility.DbaDate"))
                {
                    Value = new DateTime((long)input.Properties["Ticks"].Value);
                    return;
                }
                if ((name == "Sqlcollaborative.Dbatools.Utility.DbaDateTime") || (name == "Deserialized.Sqlcollaborative.Dbatools.Utility.DbaDateTime"))
                {
                    Value = new DateTime((long)input.Properties["Ticks"].Value);
                    return;
                }
                if ((name == "Sqlcollaborative.Dbatools.Utility.DbaTime") || (name == "Deserialized.Sqlcollaborative.Dbatools.Utility.DbaTime"))
                {
                    Value = new DateTime((long)input.Properties["Ticks"].Value);
                    return;
                }

                if (_PropertyMapping.TryGetValue(name, out mappings))
                {
                    break;
                }
            }

            if (mappings == null)
                throw new ArgumentException(String.Format("Could not interpret {0}", InputObject.GetType().FullName));

            bool test = false;
            foreach (string property in mappings)
            {
                if (input.Properties[property] != null && input.Properties[property].Value != null)
                {
                    try
                    {
                        Value = new DateTimeParameter(input.Properties[property].Value);
                        test = true;
                        break;
                    }
                    catch { }
                }
            }

            if (!test)
                throw new ArgumentException(String.Format("Could not interpret {0} (<{1}>) as valid datetime", InputObject, InputObject.GetType().Name));
        }
        #endregion Constructors

        #region Helper Methods
        /// <summary>
        /// Parses an input string as timespan
        /// </summary>
        /// <param name="Value">The string to interpret</param>
        /// <returns>The interpreted timespan value</returns>
        internal static DateTime ParseDateTime(string Value)
        {
            if (String.IsNullOrWhiteSpace(Value))
                throw new ArgumentNullException("Cannot parse empty string!");

            try { return DateTime.Parse(Value, CultureInfo.CurrentCulture); }
            catch { }
            try { return DateTime.Parse(Value, CultureInfo.InvariantCulture); }
            catch { }

            bool positive = !(Value.Contains('-'));
            string tempValue = Value.Replace("-", "").Trim();
            bool date = UtilityHost.IsLike(tempValue, "D *");
            if (date)
                tempValue = tempValue.Substring(2);
            TimeSpan timeResult = new TimeSpan();

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

            DateTime result;
            if (!positive)
                result = DateTime.Now.Add(timeResult.Negate());
            else
                result = DateTime.Now.Add(timeResult);

            if (date)
                return result.Date;
            return result;
        }
        #endregion Helper Methods
    }
}
