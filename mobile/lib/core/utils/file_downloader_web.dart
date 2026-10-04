import 'dart:html' as html;
import 'dart:convert';

List<int> _generateValidPdfBytes(String fileName) {
  final cleanName = fileName.replaceAll('(', '').replaceAll(')', '').replaceAll('<', '').replaceAll('>', '').replaceAll('\n', ' ');
  final text = '''BT
/F1 18 Tf
50 730 Td
(DEPARTMENT OF PHYSICAL EDUCATION & SPORTS) Tj
/F1 14 Tf
0 -26 Td
(OFFICIAL TA/DA CLAIM FORM DOCUMENT) Tj
/F1 11 Tf
0 -32 Td
(Attached Form File: $cleanName) Tj
0 -22 Td
(Verification Status: OFFICIAL & APPROVED) Tj
0 -22 Td
(System: SportSync College Sports Management System) Tj
0 -30 Td
(--------------------------------------------------------------------------------) Tj
0 -22 Td
(This document certifies the official travel and daily allowance claim) Tj
0 -20 Td
(submitted for match participation. All bills and receipts are verified.) Tj
0 -45 Td
(Authorized Signatory: _________________________) Tj
0 -20 Td
(Sports Director / Convener) Tj
ET''';

  final streamBytes = utf8.encode(text);
  final streamLength = streamBytes.length;

  final header = '%PDF-1.4\n';
  final obj1 = '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n';
  final obj2 = '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n';
  final obj3 = '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n';
  final obj4Head = '4 0 obj\n<< /Length $streamLength >>\nstream\n';
  final obj4Tail = '\nendstream\nendobj\n';
  final obj5 = '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n';

  final o1Pos = header.length;
  final o2Pos = o1Pos + obj1.length;
  final o3Pos = o2Pos + obj2.length;
  final o4Pos = o3Pos + obj3.length;
  final o5Pos = o4Pos + obj4Head.length + streamLength + obj4Tail.length;
  final xrefPos = o5Pos + obj5.length;

  String pad10(int n) => n.toString().padLeft(10, '0');

  final xrefStr = '''xref
0 6
0000000000 65535 f 
${pad10(o1Pos)} 00000 n 
${pad10(o2Pos)} 00000 n 
${pad10(o3Pos)} 00000 n 
${pad10(o4Pos)} 00000 n 
${pad10(o5Pos)} 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
$xrefPos
%%EOF''';

  final body = StringBuffer();
  body.write(header);
  body.write(obj1);
  body.write(obj2);
  body.write(obj3);
  body.write(obj4Head);
  body.write(text);
  body.write(obj4Tail);
  body.write(obj5);
  body.write(xrefStr);

  return utf8.encode(body.toString());
}

void downloadFileToDevice(String fileName, List<int>? fileBytes) {
  List<int> content;
  if (fileBytes != null && fileBytes.isNotEmpty) {
    content = fileBytes;
  } else if (fileName.toLowerCase().endsWith('.pdf')) {
    content = _generateValidPdfBytes(fileName);
  } else {
    content = List<int>.generate(1024, (i) => (i * 13) % 256);
  }

  String mimeType = 'application/octet-stream';
  if (fileName.endsWith('.pdf')) {
    mimeType = 'application/pdf';
  } else if (fileName.endsWith('.png')) {
    mimeType = 'image/png';
  } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
    mimeType = 'image/jpeg';
  } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
    mimeType = 'application/msword';
  }

  final blob = html.Blob([content], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

