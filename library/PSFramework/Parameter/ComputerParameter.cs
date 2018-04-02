using Microsoft.Management.Infrastructure;
using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Net;
using System.Net.NetworkInformation;
using System.Text.RegularExpressions;
using PSFramework.Utility;

namespace PSFramework.Parameter
{
    /// <summary>
    /// Parameter class that converts various input into a unified input representation
    /// </summary>
    [ParameterClass]
    public class ComputerParameter : ParameterClass
    {
        #region Fields of contract
        private string _ComputerName;
        /// <summary>
        /// The resolved computername
        /// </summary>
        [ParameterContract(ParameterContractType.Field, ParameterContractBehavior.Mandatory)]
        public string ComputerName
        {
            get { return _ComputerName; }
            set
            {
                if (!Utility.UtilityHost.IsValidComputerTarget(value))
                    throw new ArgumentException(String.Format("{0} could not be interpreted as a legal computer name", value));
                _ComputerName = value;
            }
        }
        
        /// <summary>
        /// Whether the computername is actually localhost or one of its equivalents
        /// </summary>
        [ParameterContract(ParameterContractType.Field, ParameterContractBehavior.Mandatory)]
        public bool IsLocalhost
        {
            get { return Utility.UtilityHost.IsLocalhost(ComputerName); }
        }

        /// <summary>
        /// What kind of object was passed. This makes it easier to detect and reuse specific kinds of live object in circumstances where that is desirable.
        /// </summary>
        [ParameterContract(ParameterContractType.Field, ParameterContractBehavior.Mandatory)]
        public ComputerParameterInputType Type = ComputerParameterInputType.Default;
        #endregion Fields of contract

        #region Statics & Stuff
        /// <summary>
        /// Implicitly converts the parameter class to string
        /// </summary>
        /// <param name="Parameter">The parameter to convert</param>
        [ParameterContract(ParameterContractType.Operator, ParameterContractBehavior.Conversion)]
        public static implicit operator string(ComputerParameter Parameter)
        {
            return Parameter.ComputerName;
        }

        /// <summary>
        /// Overrides the default ToString() method
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            return ComputerName;
        }
        #endregion Statics & Stuff

        #region Constructors
        /// <summary>
        /// Generates a Computer Parameter object from string
        /// </summary>
        /// <param name="ComputerName">The name to use as input</param>
        public ComputerParameter(string ComputerName)
        {
            InputObject = ComputerName;

            if (string.IsNullOrWhiteSpace(ComputerName))
                throw new ArgumentException("Computername cannot be empty!");

            string tempString = ComputerName.Trim();

            if (ComputerName == ".")
            {
                this.ComputerName = "localhost";
                return;
            }

            if(UtilityHost.IsLike(tempString, "*.WORKGROUP"))
                tempString = Regex.Replace(tempString, @"\.WORKGROUP$", "", RegexOptions.IgnoreCase);

            if (UtilityHost.IsValidComputerTarget(tempString))
            {
                this.ComputerName = tempString;
                return;
            }

            // Named Pipe path notation interpretation
            if (Regex.IsMatch(tempString, @"^\\\\[^\\]+\\pipe\\([^\\]+\\){0,1}sql\\query$", RegexOptions.IgnoreCase))
            {
                try
                {
                    this.ComputerName = Regex.Match(tempString, @"^\\\\([^\\]+)\\").Groups[1].Value;
                    return;
                }
                catch (Exception e)
                {
                    throw new ArgumentException(String.Format("Failed to interpret named pipe path notation: {0} | {1}", InputObject, e.Message), e);
                }
            }

            // Connection String interpretation
            try
            {
                System.Data.SqlClient.SqlConnectionStringBuilder connectionString = new System.Data.SqlClient.SqlConnectionStringBuilder(tempString);
                ComputerParameter tempParam = new ComputerParameter(connectionString.DataSource);
                this.ComputerName = tempParam.ComputerName;

                return;
            }
            catch (ArgumentException ex)
            {
                string name = "unknown";
                try
                {
                    name = ex.TargetSite.GetParameters()[0].Name;
                }
                catch
                {
                }
                if (name == "keyword")
                {
                    throw;
                }
            }
            catch (FormatException)
            {
                throw;
            }
            catch { }

            throw new ArgumentException(String.Format("Could not resolve computer name: {0}", ComputerName));
        }

        /// <summary>
        /// Creates a Computer Parameter from an IPAddress
        /// </summary>
        /// <param name="Address"></param>
        public ComputerParameter(IPAddress Address)
        {
            ComputerName = Address.ToString();
            InputObject = Address;
        }

        /// <summary>
        /// Creates a Computer Parameter from a PSSession
        /// </summary>
        /// <param name="Session">The session to use</param>
        public ComputerParameter(PSSession Session)
        {
            InputObject = Session;
            ComputerName = Session.ComputerName;
            Type = ComputerParameterInputType.PSSession;
        }

        /// <summary>
        /// Creates a Computer Parameter from a CimSession
        /// </summary>
        /// <param name="Session">The session to create the parameter from</param>
        public ComputerParameter(CimSession Session)
        {
            InputObject = Session;
            ComputerName = Session.ComputerName;
            Type = ComputerParameterInputType.CimSession;
        }

        /// <summary>
        /// Creates a Computer Parameter from the reply to a ping
        /// </summary>
        /// <param name="Ping">The result of a ping</param>
        public ComputerParameter(PingReply Ping)
        {
            ComputerName = Ping.Address.ToString();
            InputObject = Ping;
        }

        /// <summary>
        /// Creates a Computer Parameter from the result of a dns resolution
        /// </summary>
        /// <param name="Entry">The result of a dns resolution</param>
        public ComputerParameter(IPHostEntry Entry)
        {
            ComputerName = Entry.HostName;
            InputObject = Entry;
        }

        /// <summary>
        /// Creates a Computer Parameter from an established SQL Connection
        /// </summary>
        /// <param name="Connection">The connection to use</param>
        public ComputerParameter(System.Data.SqlClient.SqlConnection Connection)
        {
            InputObject = Connection;
            ComputerParameter tempParam = new ComputerParameter(Connection.DataSource);

            ComputerName = tempParam.ComputerName;
        }

        /// <summary>
        /// Generates a Computer Parameter object from anything
        /// </summary>
        /// <param name="InputObject"></param>
        public ComputerParameter(object InputObject)
        {
            if (InputObject == null)
                throw new ArgumentException("Input must not be null");

            PSObject input = new PSObject(InputObject);
            this.InputObject = InputObject;

            string key = "";

            foreach (string name in input.TypeNames)
            {
                if (_PropertyMapping.ContainsKey(name.ToLower()))
                {
                    key = name.ToLower();
                    break;
                }

                if (name.ToLower() == "microsoft.sqlserver.management.smo.server")
                    Type = ComputerParameterInputType.SMOServer;
            }

            if (key == "")
                throw new ArgumentException(String.Format("Could not interpret {0}", InputObject.GetType().FullName));

            foreach (string property in _PropertyMapping[key])
            {
                if (input.Properties[property] != null && input.Properties[property].Value != null && !String.IsNullOrEmpty(input.Properties[property].Value.ToString()))
                {
                    ComputerName = input.Properties[property].Value.ToString();
                    break;
                }
            }
        }
        #endregion Constructors
    }
}
