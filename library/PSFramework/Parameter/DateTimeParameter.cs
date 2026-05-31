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
        /// The time the object was created.
        /// </summary>
        public DateTime InstantiationTime;

        /// <summary>
        /// For relative time notations, what was the delta
        /// </summary>
        public TimeSpan Delta;

        /// <summary>
        /// The string value of the datetime object contained within.
        /// </summary>
        /// <returns>The string value of the datetime object contained within.</returns>
        public override string ToString()
        {
            return Value.ToString();
        }

        /// <summary>
        /// The string value of the datetime object contained within, formated as required.
        /// </summary>
        /// <param name="Format">The style in which the datetime should be formatted.</param>
        /// <returns>The string value of the datetime object contained within, formated as required.</returns>
        public string ToString(string Format)
        {
            return Value.ToString(Format);
        }

        /// <summary>
        /// Reverse the result for relative time notation provided.
        /// For example, if the the object was created with "30m" it would change the value from 30 minutes after object instantion to 30 minutes before.
        /// </summary>
        /// <param name="Throw">Whether to throw an error when the original input was not relative.</param>
        /// <exception cref="System.IO.InvalidDataException">When the original input was not a relative time notation.</exception>
        public void Reverse(bool Throw)
        {
            if (Value == InstantiationTime)
                return;
            if (Delta.TotalMilliseconds == 0)
            {
                if (Throw)
                    throw new System.IO.InvalidDataException("Original Timestamp was not relative, cannot reverse!");
                return;
            }

            Delta = Delta.Negate();
            Value = InstantiationTime.Add(Delta);
        }

        /// <summary>
        /// If relative time was provided, make sure it points into the past from object instantiation.
        /// </summary>
        public void Past()
        {
            if (Delta.TotalMilliseconds > 0)
                Reverse(false);
        }

        /// <summary>
        /// If relative time was provided, make sure it points into the future from object instantiation.
        /// </summary>
        public void Future()
        {
            if (Delta.TotalMilliseconds < 0)
                Reverse(false);
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
            InstantiationTime = DateTime.Now;
            this.Value = Value;
            InputObject = Value;
        }

        /// <summary>
        /// Creates a DateTimeParameter with a DateTime value in seconds relative to the specifiewd number.
        /// </summary>
        /// <param name="Seconds">The seconds to differ from the current time.</param>
        public DateTimeParameter(int Seconds)
        {
            InstantiationTime = DateTime.Now;
            InputObject = Seconds;
            Value = InstantiationTime.AddSeconds(Seconds);
            Delta = new TimeSpan(0, 0, Seconds);
        }

        /// <summary>
        /// Creates a TimeSpanParameter from a string object
        /// </summary>
        /// <param name="Value">The string to interpret</param>
        public DateTimeParameter(string Value)
        {
            InstantiationTime = DateTime.Now;
            this.Value = ParseDateTime(Value, this);
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

            InstantiationTime = DateTime.Now;

            PSObject input = new PSObject(InputObject);
            this.InputObject = InputObject;

            string key = "";

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
        /// <param name="Parameter">The Parameter-class to use for reference</param>
        /// <returns>The interpreted timespan value</returns>
        internal static DateTime ParseDateTime(string Value, DateTimeParameter Parameter)
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
            {
                Parameter.Delta = timeResult.Negate();
                result = Parameter.InstantiationTime.Add(timeResult.Negate());
            }
            else
            {
                Parameter.Delta = timeResult;
                result = Parameter.InstantiationTime.Add(timeResult);
            }

            if (date)
                return result.Date;
            return result;
        }
        #endregion Helper Methods
    }
}
