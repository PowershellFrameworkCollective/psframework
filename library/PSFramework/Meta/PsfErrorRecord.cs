using PSFramework.Message;
using PSFramework.Utility;
using System;
using System.IO;
using System.Management.Automation;

namespace PSFramework.Meta
{
    /// <summary>
    /// A customized error record class, enabling write access to a few properties usually only readable
    /// </summary>
    public class PsfErrorRecord : ErrorRecord
    {
        /// <summary>
        /// Create an error record based off another record
        /// </summary>
        /// <param name="Record">The record to wrap</param>
        /// <param name="ReplaceParent">Replace the original exception with your own exception</param>
        public PsfErrorRecord(ErrorRecord Record, Exception ReplaceParent)
            :base(Record, ReplaceParent)
        {

        }

        /// <summary>
        /// Create an error record based off an exception
        /// </summary>
        /// <param name="Error">The exception to wrap</param>
        /// <param name="ErrorId">An ID to attach to the error</param>
        /// <param name="Category">What kind of error happened</param>
        /// <param name="TargetObject">The target of the operation that failed</param>
        public PsfErrorRecord(Exception Error, string ErrorId, ErrorCategory Category, object TargetObject)
            :base(Error, ErrorId, Category, TargetObject)
        {
            ScriptStackTrace = UtilityHost.FriendlyCallstack.ToString("\n");
            InvocationInfo = UtilityHost.FriendlyCallstack.Entries[0].InvocationInfo;
        }


        /// <summary>
        /// Create a new error record, based off a message.
        /// </summary>
        /// <param name="Message">The message to build the error record around</param>
        /// <param name="Category">What kind of error happened</param>
        /// <param name="ErrorId">An ID to attach to the error</param>
        /// <param name="Target">The target of the operation that failed</param>
        public PsfErrorRecord(string Message, ErrorCategory Category = ErrorCategory.NotSpecified, string ErrorId = "Unspecified", object Target = null)
            :base(GetException(Message, Category), ErrorId, Category, Target)
        {
            ScriptStackTrace = UtilityHost.FriendlyCallstack.ToString("\n");
            InvocationInfo = UtilityHost.FriendlyCallstack.Entries[0].InvocationInfo;
        }

        /// <summary>
        /// Information about the context where the error happened
        /// </summary>
        public new InvocationInfo InvocationInfo { get; set; }

        /// <summary>
        /// The Stack Trace when things went bad
        /// </summary>
        public new string ScriptStackTrace { get; set; }

        /// <summary>
        /// Identify the error by its own, grand ID
        /// </summary>
        public new string FullyQualifiedErrorId { get; set; }

        /// <summary>
        /// Applies a specified CallStack to the error record
        /// </summary>
        /// <param name="Callstack">The Callstack object to write</param>
        public void SetStackTrace(CallStack Callstack)
        {
            ScriptStackTrace = Callstack.ToString("\n");
            InvocationInfo = Callstack.Entries[0].InvocationInfo;
        }

        /// <summary>
        /// Generate a new exception object from a message and an error category
        /// </summary>
        /// <param name="Message">The message to wrap into an exception</param>
        /// <param name="Category">The category of the error, determining the exception type</param>
        /// <returns>An exception</returns>
        public static Exception GetException(string Message, ErrorCategory Category)
        {
            switch (Category)
            {
                case ErrorCategory.InvalidArgument:
                    return new ArgumentException(Message);
                case ErrorCategory.InvalidOperation:
                    return new InvalidOperationException(Message);
                case ErrorCategory.InvalidData:
                    return new InvalidDataException(Message);
                case ErrorCategory.AuthenticationError:
                    return new System.Security.Authentication.AuthenticationException(Message);
                case ErrorCategory.NotImplemented:
                    return new NotImplementedException(Message);
                case ErrorCategory.ObjectNotFound:
                    return new ItemNotFoundException(Message);
                default:
                    return new Exception(Message);
            }
        }
    }
}
