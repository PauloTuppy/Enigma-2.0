import sys
import json
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

def generate_pdf(data, filename):
    doc = SimpleDocTemplate(filename, pagesize=letter)
    styles = getSampleStyleSheet()
    story = []

    # Title
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=24,
        spaceAfter=30,
        textColor=colors.HexColor('#1a237e')
    )
    story.append(Paragraph("RELATÓRIO DE INTELIGÊNCIA FINANCEIRA", title_style))
    story.append(Paragraph(f"ID OPERAÇÃO: {data.get('operation_id', 'UNKNOWN')}", styles['Normal']))
    story.append(Spacer(1, 12))

    # Executive Summary
    story.append(Paragraph("SUMÁRIO EXECUTIVO", styles['Heading2']))
    story.append(Paragraph(data.get('summary', 'N/A'), styles['Normal']))
    story.append(Spacer(1, 12))

    # Evidence Table
    story.append(Paragraph("EVIDÊNCIAS COLETADAS", styles['Heading2']))
    
    evidence_data = [['Tipo', 'Descrição', 'Timestamp']]
    for ev in data.get('evidence', []):
        evidence_data.append([ev['type'], ev['description'], ev['timestamp']])

    t = Table(evidence_data)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
        ('GRID', (0, 0), (-1, -1), 1, colors.black),
    ]))
    story.append(t)
    story.append(Spacer(1, 20))

    # OSINT Analysis
    story.append(Paragraph("ANÁLISE OSINT & VÍNCULOS", styles['Heading2']))
    story.append(Paragraph(data.get('osint_analysis', 'N/A'), styles['Normal']))
    
    # Disclaimer
    story.append(Spacer(1, 40))
    disclaimer_style = ParagraphStyle('Disclaimer', parent=styles['Normal'], fontSize=8, textColor=colors.grey)
    story.append(Paragraph("Este documento contém informações confidenciais e é destinado exclusivamente às autoridades competentes.", disclaimer_style))

    doc.build(story)
    print(f"PDF generated: {filename}")

if __name__ == "__main__":
    # Mock data for testing if run directly
    mock_data = {
        "operation_id": "OP-ENIGMA-2025-X",
        "summary": "Identificada rede de lavagem de dinheiro operando através do domínio betfake.com.br. Padrões de 'smurfing' detectados em 12.000 transações.",
        "evidence": [
            {"type": "IP Address", "description": "192.168.1.105 (VPN Node)", "timestamp": "2025-12-01 10:00:00"},
            {"type": "Transaction", "description": "R$ 50.000,00 via PIX (Laranjas)", "timestamp": "2025-12-01 10:05:00"},
        ],
        "osint_analysis": "O domínio está registrado em nome de 'Laranja S.A.'. Servidores localizados em paraíso fiscal. Conexões com IPs previamente associados ao grupo criminoso X."
    }
    
    if len(sys.argv) > 1:
        # Load from file or arg (simplified for PoC)
        pass
    
    generate_pdf(mock_data, "relatorio_confidencial.pdf")
