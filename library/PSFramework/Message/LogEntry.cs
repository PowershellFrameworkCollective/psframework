using System;

namespace PSFramework.Message
{
    /// <summary>
    /// An individual entry for the message log
    /// </summary>
    [Serializable]
    public class LogEntry
    {
        /// <summary>
        /// The message logged
        /// </summary>
        public string Message;

        /// <summary>
        /// What kind of entry was this?
        /// </summary>
        public LogEntryType Type;

        /// <summary>
        /// When was the message logged?
        /// </summary>
        public DateTime Timestamp;

        /// <summary>
        /// What function wrote the message
        /// </summary>
        public string FunctionName;

        /// <summary>
        /// What level was the message?
        /// </summary>
        public MessageLevel Level;

        /// <summary>
        /// What runspace was the message written from?
        /// </summary>
        public Guid Runspace;

        /// <summary>
        /// The computer the message was generated on
        /// </summary>
        public string ComputerName;

        /// <summary>
        /// The object that was the focus of this message.
        /// </summary>
        public object TargetObject;

        /// <summary>
        /// Creates an empty log entry
        /// </summary>
        public LogEntry()
        {

        }

        /// <summary>
        /// Creates a filled out log entry
        /// </summary>
        /// <param name="Message">The message that was logged</param>
        /// <param name="Type">The type(s) of message written</param>
        /// <param name="Timestamp">When was the message logged</param>
        /// <param name="FunctionName">What function wrote the message</param>
        /// <param name="Level">What level was the message written at.</param>
        /// <param name="Runspace">The ID of the runspace that wrote the message.</param>
        /// <param name="ComputerName">The computer the message was generated on.</param>
        /// <param name="TargetObject">The object this message was all about.</param>
        public LogEntry(string Message, LogEntryType Type, DateTime Timestamp, string FunctionName, MessageLevel Level, Guid Runspace, string ComputerName, object TargetObject)
        {
            this.Message = Message;
            this.Type = Type;
            this.Timestamp = Timestamp;
            this.FunctionName = FunctionName;
            this.Level = Level;
            this.Runspace = Runspace;
            this.ComputerName = ComputerName;
            this.TargetObject = TargetObject;
        }
    }
}