using System;

namespace PSFramework.ResultCache
{
    /// <summary>
    /// The class containing all things related to the result cache functionality.
    /// </summary>
    public static class ResultCache
    {
        /// <summary>
        /// The actually cached result
        /// </summary>
        public static object Result
        {
            get { return _Result; }
            set
            {
                _Result = value;
                _Timestamp = DateTime.Now;
            }
        }
        private static object _Result;

        /// <summary>
        /// The function that wrote the cache.
        /// </summary>
        public static string Function;

        /// <summary>
        /// Returns, when the cache was last set
        /// </summary>
        public static DateTime Timestamp
        {
            get
            {
                return _Timestamp;
            }
        }
        private static DateTime _Timestamp;

        /// <summary>
        /// Clears all cache properties to null
        /// </summary>
        public static void Clear()
        {
            _Result = null;
            Function = null;
            _Timestamp = new DateTime(0);
        }
    }
}
