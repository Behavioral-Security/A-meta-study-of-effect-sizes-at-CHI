import re
from pathlib import Path

import html2text

CCS_TOP_CLASSES = [
    "general and reference",
    "hardware",
    "computer systems organization",
    "networks",
    "software and its engineering",
    "theory of computing",
    "mathematics of computing",
    "information systems",
    "security and privacy",
    "human-centered computing",
    "computing methodologies",
    "applied computing",
    "social and professional topics"
]

CCS_SUB_GENERAL_AND_REFERENCE = [
    "surveys and overviews",
    "reference works",
    "biographs",
    "general literature",
    "computing standards, rfcs and guidelines",
    "reliability",
    "empirical studies",
    "measurement",
    "metrics",
    "evaluation",
    "experimentation",
    "estimation",
    "design",
    "performance",
    "validation",
    "verification",
    "document types",
    "cross-computing tools and techniques"
]
CCS_SUB_SECURITY_AND_PRIVACY = [
    "key management",
    "digital signatures",
    "public key encryption",
    "public key (asymmetric) techniques",
    "block and stream ciphers",
    "hash functions and message authentication codes",
    "symmetric cryptography and hash functions",
    "cryptoanalysis and other attacks",
    "information-theoretic techniques",
    "mathematical foundations of cryptography",
    "cryotography",
    "trust frameworks",
    "security requirements",
    "formal security models",
    "logic and verification",
    "formal methods and theory of security",
    "biometrics",
    "graphical / visual passwords",
    "multi-factor authentication",
    "authentication",
    "access control",
    "pseudonymity, anonymity and untraceability",
    "privacy-preserving protocols",
    "digital rights management",
    "authorization",
    "security services",
    "malware and its mitigation",
    "artificial immune systems",
    "intrusion detection systems",
    "spoofing attacks",
    "phishing",
    "social engineering attacks",
    "intrusion/anomaly detection and malware mitigation",
    "tamper-proof and tamper-resistant designs",
    "embedded systems security",
    "hardware-based security protocols",
    "hardware security implementation",
    "malicious design modifications",
    "side-channel analysis and countermeasures",
    "hardware attacks and countermeasures",
    "hardware reverse engineering",
    "security in hardware",
    "mobile platform security",
    "trusted computing",
    "virtualization and security",
    "operating systems security",
    "browser security",
    "distributed systems security",
    "information flow control",
    "denial-of-service attacks",
    "firewalls",
    "penetration testing",
    "vulnerability scanners",
    "vulnerability management",
    "file system security",
    "systems security",
    "security protocols",
    "web protocol security",
    "mobile and wireless security",
    "denial-of-service attacks",
    "firewalls",
    "network security",
    "data anonymization and sanitization",
    "management and querying of encrypted data",
    "information accountability and usage control",
    "database activity monitoring",
    "database and storage security",
    "software security engineering",
    "web application security",
    "social network security and privacy",
    "domain-specific security and privacy architectures",
    "software reverse engineering",
    "software and application security",
    "economics of security and privacy",
    "social aspects of security and privacy",
    "privacy protections",
    "usability in security and privacy",
    "human and societal aspects of security and privacy"
]
CCS_SUB_HUMAN_CENTERED_COMPUTING = [
    "user models",
    "user studies",
    "usability testing",
    "heuristic evaluations",
    "laboratory experiments",
    "field studies",
    "hci design and evaluation methods",
    "hypertext / hypermedia",
    "mixed / augmented reality",
    "command line interfaces",
    "graphical user interfaces",
    "virtual reality",
    "web-based interaction",
    "natural language interfaces",
    "collaborative interaction",
    "interaction paradigms",
    "graphics input devices",
    "displays and imagers",
    "sound-based input / output",
    "keyboards",
    "pointing devices",
    "touch screens",
    "haptic devices",
    "interaction devices",
    "hci theory, concepts and models",
    "auditory feedback",
    "text input",
    "pointing",
    "gestural input",
    "interaction techniques",
    "user interface management systems",
    "user interface programming",
    "user interface toolkits",
    "interactive systems and tools",
    "empirical studies in hci",
    "human computer interaction (hci)",
    "user interface design",
    "user centered design",
    "activity centered design",
    "scenario-based design",
    "participatory design",
    "contextual design",
    "interface design prototyping",
    "interaction design process and methods",
    "interaction design theory, concepts and paradigms",
    "empirical studies in interaction design",
    "wireframes",
    "systems and tools for interaction design",
    "interaction design",
    "social content sharing",
    "collaborative content creation",
    "collaborative filtering",
    "social recommendation",
    "social networks",
    "social tagging",
    "computer supported cooperative work",
    "social engineering (social devices)",
    "social navigation",
    "social media",
    "collaborative and social computing theory, concepts and paradigms",
    "social network analysis",
    "ethnographic studies",
    "collaborative and social computing design and evaluation methods",
    "blogs",
    "wikis",
    "reputation systems",
    "open source software",
    "social networking sites",
    "social tagging systems",
    "synchronous editor",
    "asynchronous editors",
    "collaborative and social computing systems and tools",
    "empirical studies in collaborative and social computing",
    "collaborative and social computing devices",
    "collaborative and social computing",
    "ubiquitous computing",
    "mobile computing",
    "ambient intelligence",
    "ubiquitous and mobile computing theory, concepts and paradigms",
    "ubiquitous and mobile computing systems and tools",
    "smartphones",
    "interactive whiteboards",
    "mobile phones",
    "mobile devices",
    "portable media players",
    "personal digital assistants",
    "handheld game consoles",
    "e-book readers",
    "tablet computers",
    "ubiquitous and mobile devices",
    "ubiquitous and mobile computing design and evaluation methods",
    "empirical studies in ubiquitous and mobile computing",
    "ubiquitous and mobile computing",
    "treemaps",
    "hyperbolic trees",
    "heat maps",
    "graph drawings",
    "dendrograms",
    "cladograms",
    "visualization techniques",
    "scientific visualization",
    "visual analytics",
    "geographic visualization",
    "information visualization",
    "visualization application domains",
    "visualization toolkits",
    "visualization systems and tools",
    "visualization theory, concepts and paradigms",
    "empirical studies in visualization",
    "visualization design and evaluation methods",
    "visualization",
    "accessibility theory, concepts and paradigms",
    "empirical studies in accessibility",
    "accessibility design and evaluation methods",
    "accessibility technologies",
    "accessibility systems and tools",
    "accessibility"
]
CCS_SUB_APPLIED_COMPUTING = [
    "digital cash",
    "e-commerce infrastructure",
    "electronic funds transfer",
    "online shopping",
    "online banking",
    "secure online transactions",
    "online auctions",
    "electronic commerce",
    "intranets",
    "extranets",
    "enterprise resource planning",
    "enterprise applications",
    "data centers",
    "enterprise information systems",
    "business process modeling",
    "business process management systems",
    "business process monitoring",
    "cross-organizational business processes",
    "business intelligence",
    "business process management",
    "enterprise architecture management",
    "enterprise architecture framework",
    "enterprise architecture modeling",
    "enterprise architectures",
    "service-oriented architectures",
    "event-driven architectures",
    "business rules",
    "enterprise modeling",
    "enterprise ontologies, taxonomies and vocabularies",
    "enterprise data management",
    "reference models",
    "business-it alignment",
    "it architectures",
    "it governance",
    "enterprise computing infrastructures",
    "enterprise application integration",
    "information integration and interoperability",
    "enterprise interoperability",
    "enterprise computing",
    "avionics",
    "aerospace",
    "archaeology",
    "astronomy",
    "chemistry",
    "environmental sciences",
    "earth and atmospheric sciences",
    "computer-aided design",
    "engineering",
    "pyhsics",
    "mathematics and statistics",
    "avionics",
    "electronics",
    "internet telephony",
    "Physical sciences and engineering",
    "telecommunications",
    "molecular sequence analysis",
    "recognition of genes and regulatory elements",
    "computational transcriptomics",
    "biological networks",
    "sequencing and genotyping technologies",
    "imaging",
    "computational proteomics",
    "molecular structural biology",
    "computational biology",
    "computational genomics",
    "genomics",
    "systems biology",
    "consumer health",
    "health care information systems",
    "health informatics",
    "bioinformatics",
    "metabolomics / metabonomics",
    "population genetics",
    "computational proteomics",
    "proteomics",
    "transcriptomics",
    "genetics",
    "life and medical sciences",
    "ethnography",
    "anthropogy",
    "law",
    "psychology",
    "sociology",
    "law, social and behavioral sciences",
    "surveillance mechanisms",
    "investigation techniques",
    "evidence collection, storage and analysis",
    "network forensics",
    "system forensics",
    "data recovery",
    "computer forensics",
    "fine arts",
    "performing arts",
    "computer-aided design",
    "architecture (buildings)",
    "language translation",
    "media arts",
    "sound and music computing",
    "arts and humanities",
    "digital libraries and archives",
    "publishing",
    "cyberwarfare",
    "military",
    "cartography",
    "agriculture",
    "voting / election technologies",
    "e-government",
    "computing in government",
    "word processors",
    "spreadsheets",
    "computer games",
    "microcomputers",
    "personal computers and pc applications",
    "computers in other domains",
    "consumer products",
    "supply-chain management",
    "command and control",
    "industry and manufacturing",
    "computer-aided manufacturing",
    "multi-criterion optimization and decision-making",
    "decision analysis",
    "transportation",
    "forecasting",
    "marketing",
    "Operations research",
    "digital libraries and archives",
    "computer-assisted instruction",
    "interactive learning environments",
    "collaborative learning",
    "learning management systems",
    "distance learning",
    "e-learning",
    "computer-managed instruction",
    "Education",
    "document searching",
    "text editing",
    "version control",
    "document metadata",
    "document management",
    "document analysis",
    "document scanning",
    "graphics recognition and interpretation",
    "optical character recognition",
    "online handwriting recognition",
    "document capture",
    "extensible markup language (xml)",
    "markup languages",
    "annotation",
    "format and notation",
    "multi / mixed media creation",
    "image composition",
    "hypertext / hypermedia creation",
    "document scripting languages",
    "document preparation",
    "document management and text processing"
]


class CleanedPaper:  # structure to store all information about a fully extracted paper
    def __init__(self, doi: str, authors: str, year: int, title: str, keywords: str, ccs: str,
                 specified_class: str):
        self.doi = doi
        self.authors = authors
        self.year = year
        self.title = title
        self.keywords = keywords
        self.ccs = ccs
        self.specified_class = specified_class

    # extract Content of html files into plain txt format for easier handling and content extraction


def get_plaintext(html_input_path):
    # initialize html2text converter with bundle of options listed below
    html_converter = html2text.HTML2Text()
    html_converter.ignore_links = True
    html_converter.ignore_images = True
    html_converter.images_to_alt = True
    html_converter.ignore_tables = True
    html_converter.ignore_mailto_links = True
    html_converter.skip_internal_links = True
    html_converter.use_automatic_links = False
    html_converter.body_width = 0  # no body_width so no inserted linebreaks
    html_converter.white_space_trim = True
    with open(html_input_path, "r", encoding="utf-8") as html_content:
        text = html_converter.handle(html_content.read())
    return text


def clean_paper(plain_text):
    # extract title from plaintext via first '\n' identification
    title = plain_text.split("\n\n")[0]
    title = title[2:len(title) - 1].replace("\n", " ")  # remove leading '#' and trailing '\n' in title

    # extract doi from plaintext
    try:
        doi = re.split("DOI:", plain_text, flags=re.IGNORECASE)[1]  # split after "DOI:" until next '\n'
        doi = doi.split("\n")[0].strip()
    except IndexError:
        doi = "undefined"

    # extract authors as list from plaintext
    authors = list()
    tmp_authors = re.split("DOI", plain_text, flags=re.IGNORECASE)[0]  # split before "DOI"
    tmp_authors = tmp_authors.split("\n\n")[1:]  # split after first complete empty line (\n\n)
    for author in tmp_authors:
        author = author.split(",")[0].strip()
        if len(author) > 2:
            authors.append(author)  # extract authors name from whole author-information
    authors = ";".join(authors)

    # extract year of publication from plain text
    year = plain_text.split("DOI")[1].split("\n")[1].strip().split(",")[-1].split(" ")[-1].strip()
    try:
        year = int(year)
    except ValueError:  # if no year could be extracted, define year as -1
        year = int(-1)

    # extract given full CCS classification tree from plaintext
    try:
        ccs = re.split("CCS CONCEPTS:", plain_text, flags=re.IGNORECASE)[
            1]  # split after "CCS concepts:" until next '\n'
        ccs = ccs.split("\n")[0]
    except IndexError:
        ccs = "undefined"

    # extract most important CCS classification branch from given ccs concepts
    specified_class = []  # default fallback to have the most general classification at least
    # specified_class extraction in own text

    ccs_splitted = ccs.lower().split(";")  # split given ccs Classification from Plaintext

    def extract_precise_classifications(given, ccs_split, category, sub_category):
        if category in given:
            for detailed_class in sub_category:
                if detailed_class in ccs_split and detailed_class not in specified_class:
                    specified_class.append(detailed_class)

    for ccs_split in ccs_splitted:
        for given in CCS_TOP_CLASSES:
            if given in ccs_split:
                # Extract detailed classifications for specific categories
                extract_precise_classifications(given, ccs_split, 'general and reference',
                                                CCS_SUB_GENERAL_AND_REFERENCE)
                extract_precise_classifications(given, ccs_split, 'human-centered computing',
                                                CCS_SUB_HUMAN_CENTERED_COMPUTING)
                extract_precise_classifications(given, ccs_split, 'applied computing', CCS_SUB_APPLIED_COMPUTING)
                extract_precise_classifications(given, ccs_split, 'security and privacy', CCS_SUB_SECURITY_AND_PRIVACY)

                # Add the top-level classification if not already added
                if given not in specified_class:
                    specified_class.append(given)

    specified_class = ";".join(specified_class)  # join list of given classes as string seperated by semicolon

    # extract given keywords from plaintext
    try:
        keywords = re.split("KEYWORDS:", plain_text, flags=re.IGNORECASE)[1]  # split after "Keywords:" until next '\n'
        keywords = keywords.split("\n")[0]
        keywords = re.sub(r'\s*[;,]\s*', ',', keywords)
        keywords = keywords.split(",")
    except IndexError:  # if no keywords are find, define them as "undefined"
        keywords = "undefined"

    return CleanedPaper(doi=doi, authors=authors, year=year, title=title, keywords=keywords, ccs=ccs,
                        specified_class=specified_class)  # return cleanedPaper instance with all fields setted


def get_header(html_path: Path):
    plaintext = get_plaintext(html_path)
    result = clean_paper(plaintext)
    # if paper contains "undefined" in ccs column, it is most likely not in the correct format and therefor not usable.
    if not result.ccs == "undefined":
        json_data = {'title': result.title, 'topics': result.specified_class.split(";"),
                     'authors': result.authors.split(";"), 'year': result.year}

        # set all fields with information from cleanedPaper named result
        if result.doi.__contains__("doi.org/"):  # extract and build doi-links if necessary
            json_data['doi'] = result.doi.split("doi.org/")[1]
            json_data['link'] = result.doi
        else:
            json_data['doi'] = result.doi
            json_data['link'] = "https://doi.org/" + result.doi

        return json_data

    else:
        return {"title": "error in CCS extraction"}


# test
if __name__ == "__main__":
    papers = [
        "3445109.html",
    ]
    html_path = ""

    for paper in papers:
        print(get_header(Path(html_path + "/" + paper)))
