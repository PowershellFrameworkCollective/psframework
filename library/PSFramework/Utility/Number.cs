using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Utility
{
    /// <summary>
    /// Wrapper class around double to facilitate human-friendly formatting in object properties
    /// </summary>
    public class Number : IComparable<Number>, IComparable
    {
        /// <summary>
        /// The actual value being wrapped
        /// </summary>
        public double Value;

        #region ToString
        /// <summary>
        /// Provides a user friendly representation of a number
        /// </summary>
        /// <returns>A user friendly number format</returns>
        public override string ToString()
        {
            string left;
            string right = "";

            // Determine right part of decimal separator
            string tempRight = (Value - Math.Truncate(Value)).ToString();
            if (tempRight == "0")
                tempRight = "";
            else
                tempRight = tempRight.Substring(2);
            if ((DecimalDigits < 0)  || (tempRight.Length <= DecimalDigits))
                right = tempRight;
            else if (DecimalDigits > 0)
                right = tempRight.Substring(0, DecimalDigits);

            // Determine left part of decimal separator
            string tempLeft = Math.Truncate(Value).ToString();
            if (SegmentSize <= 0)
                left = tempLeft;
            else if (SegmentSize >= tempLeft.Length)
                left = tempLeft;
            else
            {
                int remaining = tempLeft.Length % SegmentSize;
                int index = remaining;
                left = tempLeft.Substring(0, remaining);
                while (index < tempLeft.Length)
                {
                    left += $"{SegmentSeparator}{tempLeft.Substring(index, SegmentSize)}";
                    index += SegmentSize;
                }
            }

            if (String.IsNullOrEmpty(right))
                return left;
            return $"{left}{DecimalSeparator}{right}";
        }
        #endregion ToString

        #region Format Configuration
        private int? _SegmentSize;
        /// <summary>
        /// Size of each segment before the decimal seaparator when displaying numbers
        /// </summary>
        public int SegmentSize
        {
            get
            {
                if (_SegmentSize == null)
                    return UtilityHost.NumberSegmentSize;
                return (int)_SegmentSize;
            }
            set { _SegmentSize = value; }
        }

        private string _SegmentSeparator;
        private bool _SegmentSeparatorSet = false;
        /// <summary>
        /// The seperator used inbetween each segment when displaying numbers
        /// </summary>
        public string SegmentSeparator
        {
            get
            {
                if (!_SegmentSeparatorSet)
                    return UtilityHost.NumberSegmentSeparator;
                return _SegmentSeparator;
            }
            set
            {
                _SegmentSeparatorSet = true;
                _SegmentSeparator = value; 
            }
        }

        private string _DecimalSeparator;
        private bool _DecimalSeparatorSet = false;
        /// <summary>
        /// The decimal seperator when displaying numbers
        /// </summary>
        public string DecimalSeparator
        {
            get
            {
                if (!_DecimalSeparatorSet)
                    return UtilityHost.NumberDecimalSeparator;
                return _DecimalSeparator;
            }
            set
            {
                _DecimalSeparatorSet = true;
                _DecimalSeparator = value;
            }
        }

        private int? _DecimalDigits;
        /// <summary>
        /// When displaying numbers, how many digits after the decimal seperator will be shown?
        /// </summary>
        public int DecimalDigits
        {
            get
            {
                if (_DecimalDigits == null)
                    return UtilityHost.NumberDecimalDigits;
                return (int)_DecimalDigits;
            }
            set { _DecimalDigits = value; }
        }
        #endregion Format Configuration

        #region Constructors
        /// <summary>
        /// Create an empty number
        /// </summary>
        public Number()
        {

        }

        /// <summary>
        /// Create a number with an initial value
        /// </summary>
        /// <param name="Value">The initial value of the number</param>
        public Number(double Value)
        {
            this.Value = Value;
        }
        #endregion Constructors

        #region Interface Implementations
        /// <inheritdoc cref="IComparable{Number}.CompareTo"/>
        /// <remarks>For sorting</remarks>
        public int CompareTo(Number obj)
        {
            return Value.CompareTo(obj.Value);
        }

        /// <inheritdoc cref="IComparable.CompareTo"/>
        /// <remarks>For sorting</remarks>
        /// <exception cref="ArgumentException">If you compare with something invalid.</exception>
        public int CompareTo(object obj)
        {
            var number = obj as Number;
            if (number != null)
            {
                return CompareTo(number);
            }
            throw new ArgumentException(String.Format("Cannot compare a {0} to a {1}", typeof(Number).FullName, obj.GetType().FullName));
        }
        #endregion Interface Implementations

        #region MathOperators
        /// <summary>
        /// Adds two sizes
        /// </summary>
        /// <param name="a">The first size to add</param>
        /// <param name="b">The second size to add</param>
        /// <returns>The sum of both sizes</returns>
        public static Number operator +(Number a, Number b)
        {
            return new Number(a.Value + b.Value);
        }

        /// <summary>
        /// Substracts two sizes
        /// </summary>
        /// <param name="a">The first size to substract</param>
        /// <param name="b">The second size to substract</param>
        /// <returns>The difference between both sizes</returns>
        public static Number operator -(Number a, Number b)
        {
            return new Number(a.Value - b.Value);
        }

        /// <summary>
        /// Multiplies two sizes with each other
        /// </summary>
        /// <param name="a">The size to multiply</param>
        /// <param name="b">The size to multiply with</param>
        /// <returns>A multiplied size.</returns>
        public static Number operator *(Number a, double b)
        {
            return new Number(a.Value * b);
        }

        /// <summary>
        /// Divides one size by another. 
        /// </summary>
        /// <param name="a">The size to divide</param>
        /// <param name="b">The size to divide with</param>
        /// <returns>Divided size (note: Cut off)</returns>
        public static Number operator /(Number a, double b)
        {
            return new Number(a.Value / b);
        }

        /// <summary>
        /// Multiplies two sizes with each other
        /// </summary>
        /// <param name="a">The size to multiply</param>
        /// <param name="b">The size to multiply with</param>
        /// <returns>A multiplied size.</returns>
        public static Number operator *(Number a, Number b)
        {
            return new Number(a.Value * b.Value);
        }

        /// <summary>
        /// Divides one size by another.
        /// </summary>
        /// <param name="a">The size to divide</param>
        /// <param name="b">The size to divide with</param>
        /// <returns>Divided size (note: Cut off)</returns>
        public static Number operator /(Number a, Number b)
        {
            return new Number(a.Value / b.Value);
        }

        #endregion
        #region ImplicitCasts

        /// <summary>
        /// Implicitly converts int to size
        /// </summary>
        /// <param name="a">The number to convert</param>
        public static implicit operator Number(int a)
        {
            return new Number(a);
        }

        /// <summary>
        /// Implicitly converts int to size
        /// </summary>
        /// <param name="a">The number to convert</param>
        public static implicit operator Number(decimal a)
        {
            return new Number((long)a);
        }

        /// <summary>
        /// Implicitly converts size to int
        /// </summary>
        /// <param name="a">The size to convert</param>
        public static implicit operator Int32(Number a)
        {
            return (Int32)a.Value;
        }

        /// <summary>
        /// Implicitly converts long to size
        /// </summary>
        /// <param name="a">The number to convert</param>
        public static implicit operator Number(long a)
        {
            return new Number(a);
        }

        /// <summary>
        /// Implicitly converts size to long
        /// </summary>
        /// <param name="a">The size to convert</param>
        public static implicit operator Int64(Number a)
        {
            return (long)a.Value;
        }

        /// <summary>
        /// Implicitly converts string to size
        /// </summary>
        /// <param name="a">The string to convert</param>
        public static implicit operator Number(String a)
        {
            return new Number(Double.Parse(a));
        }

        /// <summary>
        /// Implicitly converts double to size
        /// </summary>
        /// <param name="a">The number to convert</param>
        public static implicit operator Number(double a)
        {
            return new Number(a);
        }

        /// <summary>
        /// Implicitly converts size to double
        /// </summary>
        /// <param name="a">The size to convert</param>
        public static implicit operator double(Number a)
        {
            return a.Value;
        }
        #endregion ImplicitCasts
    }
}
