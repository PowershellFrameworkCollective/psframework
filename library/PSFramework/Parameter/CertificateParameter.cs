using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography.X509Certificates;

namespace PSFramework.Parameter
{
    /// <summary>
    /// Parameter Class to help automate certificate store lookup but also accept a pure certificate object
    /// </summary>
    public class CertificateParameter
    {
        /// <summary>
        /// The certificate as it was resolved to
        /// </summary>
        public X509Certificate2 Certificate
        {
            get => _certificate;
            set
            {
                if (!value.HasPrivateKey)
                    throw new ArgumentException("Certificate must have private key!");
                _certificate = value;
            }
        }
        private X509Certificate2 _certificate;

        /// <summary>
        /// Fill out the parameter class with a certificate object
        /// </summary>
        /// <param name="Certificate">The certificate to use</param>
        public CertificateParameter(X509Certificate2 Certificate)
        {
            _certificate = Certificate;
        }

        /// <summary>
        /// Fill out the parameter class by searching in the local certificate stores for a certificate with matching thumbprint or subject.
        /// Will select the longest-lasting valid certificate with a private key
        /// </summary>
        /// <param name="Name">Thumbprint or subject to resolve into a certificate</param>
        /// <exception cref="ArgumentException">Will be thrown when no certificate has been found</exception>
        /// <exception cref="InvalidDataException">Will be thrown when a certificate was found, but it was not valid (expired or no private key)</exception>
        public CertificateParameter(string Name)
        {
            List<X509Certificate2> certificates = new List<X509Certificate2>();

            X509Store store = new X509Store(StoreLocation.CurrentUser);
            store.Open(OpenFlags.ReadOnly);
            foreach (X509Certificate2 cert in store.Certificates)
                if (IsMatch(Name, cert))
                    certificates.Add(cert);
            store.Close();

            store = new X509Store(StoreLocation.LocalMachine);
            store.Open(OpenFlags.ReadOnly);
            foreach (X509Certificate2 cert in store.Certificates)
                if (IsMatch(Name, cert))
                    certificates.Add(cert);
            store.Close();

            if (certificates.Count == 0)
                throw new ArgumentException($"Certificate not found: {Name}");

            X509Certificate2 certificate = certificates.Where(c => c.HasPrivateKey && c.NotAfter > DateTime.Now && c.NotBefore < DateTime.Now).OrderBy(c => c.NotAfter.Ticks * -1).First();
            if (null == certificate)
                throw new InvalidDataException($"No valid certificate with private key found: {Name}");
            Certificate = certificate;
        }

        private static bool IsMatch(string Name, X509Certificate2 Certificate)
        {
            return String.Equals(Name, Certificate.Thumbprint, StringComparison.OrdinalIgnoreCase) || String.Equals(Name, Certificate.Subject, StringComparison.OrdinalIgnoreCase);
        }

        /// <summary>
        /// Converts a CertificateParameter into certificate object.
        /// </summary>
        /// <param name="Parameter">The CertificateParameter to convert</param>
        public static implicit operator X509Certificate(CertificateParameter Parameter) => Parameter.Certificate;

        /// <summary>
        /// Converts a CertificateParameter into certificate object.
        /// </summary>
        /// <param name="Parameter">The CertificateParameter to convert</param>
        public static implicit operator X509Certificate2(CertificateParameter Parameter) => Parameter.Certificate;

        /// <summary>
        /// Converts a certificate object into a CertificateParameter.
        /// </summary>
        /// <param name="Cert"></param>
        public static implicit operator CertificateParameter(X509Certificate2 Cert) => new CertificateParameter(Cert);

        /// <summary>
        /// The default string representation of the object
        /// </summary>
        /// <returns>Returns the string representation of the certificate or a placeholder when null.</returns>
        public override string ToString()
        {
            if (null == Certificate)
                return "<null>";
            return Certificate.ToString();
        }
    }
}
