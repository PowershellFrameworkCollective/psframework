using PSFramework.Parameter;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Utility
{
    /// <summary>
    /// Wraps a timespan and presents it in a human-friendly readable way.
    /// </summary>
    public class HumanizedTimeSpan : TimeSpanParameter
    {
        /// <summary>
        /// How many digits after the dot are used for representing time
        /// </summary>
        public int Digits = 2;

        #region Constructors
        /// <summary>
        /// Creates a HumanizedTimeSpan from a TimeSpan object (not the hardest challenge)
        /// </summary>
        /// <param name="Value">The timespan object to accept</param>
        public HumanizedTimeSpan(TimeSpan Value)
            : base(Value)
        {
            
        }

        /// <summary>
        /// Creates a HumanizedTimeSpan from integer, assuming it to mean seconds
        /// </summary>
        /// <param name="Seconds">The seconds to run</param>
        public HumanizedTimeSpan(int Seconds)
            : base(Seconds)
        {
            
        }

        /// <summary>
        /// Creates a HumanizedTimeSpan from a string object
        /// </summary>
        /// <param name="Value">The string to interpret</param>
        public HumanizedTimeSpan(string Value)
            : base(Value)
        {
            
        }

        /// <summary>
        /// Creates a HumanizedTimeSpan from any kind of object it has been taught to understand
        /// </summary>
        /// <param name="InputObject">The object to interpret</param>
        public HumanizedTimeSpan(object InputObject)
            : base(InputObject)
        {
            
        }
        #endregion Constructors

        /// <summary>
        /// Creates extra-nice timespan formats
        /// </summary>
        /// <returns>Humanly readable timespans</returns>
        public override string ToString()
        {
            if (Value.TotalSeconds < 1)
                return Math.Round(Value.TotalMilliseconds, Digits).ToString() + " ms";
            else if (Value.TotalSeconds <= 60)
                return Math.Round(Value.TotalSeconds, Digits).ToString() + " s";
            else
            {
                if (Value.Ticks % 10000000 == 0) { return Value.ToString(); }
                else
                {
                    string temp = Value.ToString();
                    temp = temp.Substring(0, temp.LastIndexOf("."));
                    return temp;
                }
            }
        }

        #region Implicit Operators
        /// <summary>
        /// Implicitly converts a DbaTimeSpan object into a TimeSpan object
        /// </summary>
        /// <param name="Base">The original object to revert</param>
        public static implicit operator TimeSpan(HumanizedTimeSpan Base)
        {
            try { return Base.Value; }
            catch { }
            return new TimeSpan();
        }

        /// <summary>
        /// Implicitly converts a TimeSpan object into a DbaTimeSpan object
        /// </summary>
        /// <param name="Base">The original object to wrap</param>
        public static implicit operator HumanizedTimeSpan(TimeSpan Base)
        {
            return new HumanizedTimeSpan(Base);
        }
        #endregion Implicit Operators
    }
}
