class SeedWorkflowTemplates
  PHASES = [
    { position: 1, code: "relacion_comercial", name: "Relacion Comercial", owner_role: "Export Manager", timeline_start: "T-180+", timeline_end: "T-90", description: "Contrato, orden de compra y especificaciones comerciales." },
    { position: 2, code: "programa_produccion", name: "Programa de Produccion", owner_role: "Planificacion", timeline_start: "T-45", timeline_end: "T-12", description: "Asignacion de lote, orden de trabajo y confirmacion de fecha." },
    { position: 3, code: "positive_release", name: "Positive Release", owner_role: "Export Manager", timeline_start: "T-15", timeline_end: "T-12", description: "CoA y aprobacion del comprador cuando aplica." },
    { position: 4, code: "booking", name: "Booking", owner_role: "COMEX", timeline_start: "T-10", timeline_end: "T-7", description: "Cotizacion y reserva de espacio en buque." },
    { position: 5, code: "instructivo_operativo", name: "Instructivo Operativo", owner_role: "COMEX", timeline_start: "T-7", timeline_end: "T-7", description: "Nodo central que dispara actores y documentos aguas abajo." },
    { position: 6, code: "carga_despacho", name: "Carga y Despacho Fisico", owner_role: "Planta / Transporte", timeline_start: "T-5", timeline_end: "T-3", description: "Coordinacion, carga, VGM y guia de despacho." },
    { position: 7, code: "certificaciones_tramites", name: "Certificaciones y Tramites", owner_role: "Agente de Aduanas", timeline_start: "T-5", timeline_end: "T-1", description: "SAG, origen, DUS, matriz BL y documentos bancarios." },
    { position: 8, code: "post_zarpe_cobro", name: "Post-Zarpe y Cobro", owner_role: "COMEX / Export Manager", timeline_start: "T+1", timeline_end: "T+60", description: "BL final, set documentario y reconciliacion de pago." },
  ].freeze

  DOCUMENTS = [
    { phase: "relacion_comercial", step: 1, code: "master_agreement", name: "Master Agreement", timeline: "T-180+", type: "master", category: "documento", obligation: "obligatorio", criticality: "alto", grain: "relacion_comercial", generators: [ "Export Manager" ], receivers: [ "Comprador" ], description: "Contrato marco plurianual que define condiciones generales.", state: "Firmado offline; vive en carpeta o email sin versionado.", risk: "Sin fuente unica del contrato vigente.", sot: "Nombre legal del shipper, condiciones generales, descripcion/HS con Product Spec.", key_data: "Partes, razon social exacta, vigencia, incoterm marco, terminos de pago, calidad, disputas." },
    { phase: "relacion_comercial", step: 2, code: "purchase_order", name: "Purchase Order", timeline: "T-90", type: "master", category: "documento", obligation: "obligatorio", criticality: "critico", grain: "po", generators: [ "Comprador" ], receivers: [ "Export Manager" ], description: "Orden de compra por embarque; trigger formal del proceso operativo.", state: "Email PDF validado manualmente por Export Manager.", risk: "Puede llegar directo a COMEX sin revision comercial.", sot: "Cantidades, precio, incoterm, consignee/notify.", key_data: "PO, fecha, comprador, SKU, cantidades, precio, moneda, incoterm, destino, entrega." },
    { phase: "relacion_comercial", step: 3, code: "product_spec", name: "Product Spec / Packaging / Label", timeline: "T-90", type: "master", category: "documento", obligation: "obligatorio", criticality: "critico", grain: "sku_producto", generators: [ "Comprador" ], receivers: [ "Export Manager" ], description: "Especificaciones tecnicas, packaging y arte de etiqueta.", state: "Email PDFs reenviados manualmente a Planta y QA.", risk: "Sin versionado formal; Planta y COMEX pueden tener versiones distintas.", sot: "MRL, specs de calidad, descripcion/HS, peso neto por unidad.", key_data: "SKU, humedad, aw, MRL, microbiologia, aflatoxinas, packaging, label, peso neto, HS." },
    { phase: "programa_produccion", step: 4, code: "production_program_entry", name: "Ingreso al Programa de Produccion", timeline: "T-45", type: "operacional", category: "artefacto", obligation: "obligatorio", criticality: "medio", grain: "po", generators: [ "Export Manager" ], receivers: [ "Planificacion", "Planta" ], description: "Ingreso del negocio al sistema productivo con datos del PO.", state: "Ingreso manual en ERP, sistema de produccion o Word.", risk: "No valida label aprobado ni MRL de destino.", key_data: "Producto, cantidad, cliente, etiqueta, fecha requerida." },
    { phase: "programa_produccion", step: 5, code: "lot_assignment", name: "Asignacion de Lote / Inventario", timeline: "T-30", type: "operacional", category: "artefacto", obligation: "obligatorio", criticality: "alto", grain: "lote", generators: [ "Planificacion" ], receivers: [ "COMEX", "Export Manager" ], description: "Planificacion asigna lote al PO y centro de costo.", state: "Asignacion en SAP/WMS informada a COMEX.", risk: "Puede no cruzar requisitos del comprador.", key_data: "Lote, SKU, disponible, bodega, centro de costo, cosecha/proceso." },
    { phase: "programa_produccion", step: 6, code: "work_order", name: "Orden de Trabajo", timeline: "T-25", type: "derivado", category: "documento", obligation: "obligatorio", criticality: "alto", grain: "lote", generators: [ "Planificacion" ], receivers: [ "Planta / Maquila" ], description: "Instruccion formal a planta para producir lote asignado.", state: "Emitida en ERP o Word/Excel.", risk: "No valida label ni MRL antes de ordenar produccion.", key_data: "OT, lote, SKU, cantidad, packaging, label aprobado, fecha objetivo, linea/planta." },
    { phase: "programa_produccion", step: 7, code: "production_date_confirmation", name: "Confirmacion Fecha de Produccion", timeline: "T-12", type: "operacional", category: "artefacto", obligation: "obligatorio", criticality: "alto", grain: "embarque", generators: [ "Planta / Maquila" ], receivers: [ "COMEX" ], description: "Fecha en que producto estara listo para retiro.", state: "WhatsApp o telefono sin registro formal.", risk: "Confirmacion verbal puede no cumplirse.", key_data: "OT, fecha lista para retiro, cantidad efectiva, responsable planta." },
    { phase: "positive_release", step: 8, code: "certificate_of_analysis", name: "Certificate of Analysis (CoA)", timeline: "T-15", type: "externo", category: "documento", obligation: "condicional", criticality: "critico", grain: "lote", generators: [ "Lab Externo" ], receivers: [ "COMEX", "Export Manager" ], description: "Resultados analiticos del lote.", state: "Lab manda PDF; QA revisa MRL manualmente.", risk: "Trabajo manual por lote y sin validacion automatica contra destino.", sot: "Resultados analiticos inapelables.", key_data: "Lote, fecha, lab, humedad, aw, pesticidas vs MRL, aflatoxinas, microbiologia, pass/fail." },
    { phase: "positive_release", step: 9, code: "positive_release", name: "Positive Release", timeline: "T-12", type: "externo", category: "artefacto", obligation: "condicional", criticality: "alto", grain: "lote", generators: [ "Export Manager" ], receivers: [ "Comprador" ], description: "Aprobacion explicita del comprador sobre el CoA.", state: "Respuesta por email sin tracking.", risk: "Si se rechaza el lote, COMEX no puede confirmar booking.", key_data: "Lote, CoA, aprobacion comprador, fecha, responsable." },
    { phase: "booking", step: 10, code: "freight_quote", name: "Cotizacion de Flete", timeline: "T-10", type: "operacional", category: "artefacto", obligation: "recomendado", criticality: "medio", grain: "embarque", generators: [ "COMEX" ], receivers: [ "Forwarder" ], description: "Tarifa y disponibilidad de espacio en buque.", state: "Email o telefono; comparacion en Excel.", risk: "Sin historial ni comparacion automatica.", key_data: "Forwarder, naviera, POL/POD, tarifa, contenedor, transito, validez." },
    { phase: "booking", step: 11, code: "booking_confirmation", name: "Booking Confirmation", timeline: "T-7", type: "externo", category: "documento", obligation: "obligatorio", criticality: "critico", grain: "embarque", generators: [ "Forwarder" ], receivers: [ "COMEX" ], description: "Reserva de espacio en buque y cut-offs.", state: "Forwarder confirma por email.", risk: "Puede caer si no hay stock.", sot: "Buque, viaje, cut-offs, POL/POD, contenedor con Loading Report.", key_data: "Booking, buque, viaje, POL/POD, ETD/ETA, cut-offs, gate-in, contenedores." },
    { phase: "instructivo_operativo", step: 12, code: "shipping_instruction", name: "Instructivo de Embarque", timeline: "T-7", type: "derivado", category: "documento", obligation: "obligatorio", criticality: "critico", grain: "embarque", generators: [ "COMEX" ], receivers: [ "Agente de Aduanas", "Planificacion", "Forwarder", "Transporte" ], description: "Documento central que consolida datos comerciales, logisticos y especiales.", state: "Word o Excel manual enviado por email.", risk: "Agente re-digita todo; transporte puede recibir datos de precio.", key_data: "Shipper, consignee, notify, HS, producto, cantidades, pesos proyectados, booking, incoterm." },
    { phase: "carga_despacho", step: 13, code: "land_transport_coordination", name: "Coordinacion Transporte Terrestre", timeline: "T-5", type: "operacional", category: "artefacto", obligation: "obligatorio", criticality: "medio", grain: "embarque", generators: [ "COMEX" ], receivers: [ "Transporte", "Planta" ], description: "Coordinacion del camion para retiro y entrega a depot/puerto.", state: "WhatsApp o telefono.", risk: "Camion tarde o planta no lista arriesga gate-in.", key_data: "Transportista, horario planta, patente, contenedor, depot/puerto." },
    { phase: "carga_despacho", step: 14, code: "container_loading_vgm", name: "Container Loading Report + VGM", timeline: "T-3", type: "cuadratura_fisica", category: "documento", obligation: "obligatorio", criticality: "critico", grain: "contenedor", generators: [ "Planta / Maquila" ], receivers: [ "COMEX", "Forwarder" ], description: "Carga del contenedor y peso bruto verificado SOLAS.", state: "Excel o papel enviado por WhatsApp/email.", risk: "VGM tardio impide zarpe.", sot: "Peso bruto verificado, sello, contenedor con Booking.", key_data: "Contenedor, sello, VGM, metodo pesaje, cantidad cargada, fecha/hora, bascula." },
    { phase: "carga_despacho", step: 15, code: "dispatch_guide", name: "Guia de Despacho", timeline: "T-3", type: "cuadratura_fisica", category: "documento", obligation: "obligatorio", criticality: "critico", grain: "contenedor", generators: [ "Planta / Maquila" ], receivers: [ "COMEX", "Transporte", "Agente de Aduanas" ], description: "Documento tributario que certifica salida fisica.", state: "Emitida al retiro; COMEX verifica manualmente.", risk: "No se cruza automaticamente contra instructivo.", sot: "Peso neto, bultos/cajas/pallets, lote fisico.", key_data: "Guia, lote, SKU, cantidad, peso neto, destinatario, patente, fecha." },
    { phase: "certificaciones_tramites", step: 16, code: "fumigation_certificate", name: "Fumigation Certificate", timeline: "T-5", type: "externo", category: "documento", obligation: "condicional", criticality: "medio", grain: "embarque", destinations: [ "India" ], generators: [ "Fumigadora Externa" ], receivers: [ "COMEX" ], description: "Certificado de fumigacion si destino lo exige.", state: "Certificado fisico y PDF.", risk: "Queda no aplica para la mayoria de destinos.", key_data: "Certificado, fumigante, dosis, fecha, exposicion, empresa, contenedor." },
    { phase: "certificaciones_tramites", step: 17, code: "phytosanitary_certificate", name: "Phytosanitary Certificate (SAG)", timeline: "T-3", type: "regulatorio", category: "documento", obligation: "obligatorio", criticality: "critico", grain: "embarque", generators: [ "Agente de Aduanas", "SAG" ], receivers: [ "COMEX" ], description: "Certificado fitosanitario oficial.", state: "Agente ingresa solicitud SAG desde instructivo.", risk: "Error en instructivo genera error en Phyto.", key_data: "Certificado, descripcion oficial, destino, lote, shipper/consignee, tratamiento, inspeccion." },
    { phase: "certificaciones_tramites", step: 18, code: "commercial_invoice", name: "Commercial Invoice", timeline: "T-3", type: "derivado", category: "documento", obligation: "obligatorio", criticality: "critico", grain: "embarque", generators: [ "COMEX" ], receivers: [ "Agente de Aduanas", "Comprador" ], description: "Factura de exportacion y verdad financiera del embarque.", state: "ERP/SAP o Word; a veces generada por agente.", risk: "Monto o nombres distintos detienen cobro bancario.", sot: "Monto a cobrar.", key_data: "Factura, shipper/consignee, HS, cantidades, precio, moneda, incoterm, pago, monto." },
    { phase: "certificaciones_tramites", step: 18, code: "packing_list", name: "Packing List", timeline: "T-3", type: "derivado", category: "documento", obligation: "obligatorio", criticality: "alto", grain: "embarque", generators: [ "COMEX" ], receivers: [ "Agente de Aduanas", "Comprador" ], description: "Lista de empaque con bultos, pesos y contenido.", state: "ERP/SAP o Word cruzando Loading Report.", risk: "Peso o cantidades incorrectas arrastran error al BL.", key_data: "Bultos, cajas, pallets, peso neto/bruto, dimensiones, contenido, contenedor, sello." },
    { phase: "certificaciones_tramites", step: 19, code: "certificate_of_origin", name: "Certificate of Origin (COO)", timeline: "T-2", type: "regulatorio", category: "documento", obligation: "condicional", criticality: "alto", grain: "embarque", destinations: [ "China", "EU", "India" ], generators: [ "Agente de Aduanas", "Camara de Comercio" ], receivers: [ "COMEX" ], description: "Certificado de origen para beneficios arancelarios.", state: "Portales por destino, algunos en papel.", risk: "Ingreso manual desde instructivo.", key_data: "Origen, HS, criterio origen, shipper/consignee, factura." },
    { phase: "certificaciones_tramites", step: 20, code: "bl_matrix", name: "Matriz BL -> Portal Forwarder", timeline: "T-2", type: "derivado", category: "artefacto", obligation: "obligatorio", criticality: "critico", grain: "embarque", generators: [ "Agente de Aduanas" ], receivers: [ "Forwarder" ], description: "Ingreso manual de datos al portal del forwarder.", state: "Copia campo por campo desde instructivo y guia.", risk: "Typo genera amendment de BL.", key_data: "Shipper/consignee/notify, HS, cantidades, pesos, contenedor, sello, POL/POD, flete." },
    { phase: "certificaciones_tramites", step: 21, code: "dus", name: "DUS - Declaracion Unica de Salida", timeline: "T-1", type: "regulatorio", category: "documento", obligation: "obligatorio", criticality: "critico", grain: "embarque", generators: [ "Agente de Aduanas" ], receivers: [ "Aduana Chile" ], description: "Declaracion aduanera ante Aduana Chile en SICEX.", state: "Provisoria, aceptacion, gate-in y definitiva.", risk: "Incoterm o HS errado impacta valor declarado.", key_data: "DUS, RUT exportador, HS, valor FOB, incoterm, cantidades, pesos, destino, factura, Phyto." },
    { phase: "certificaciones_tramites", step: nil, code: "marine_insurance", name: "Marine Insurance (Poliza)", timeline: "T-2", type: "externo", category: "documento", obligation: "condicional", criticality: "medio", grain: "embarque", generators: [ "Aseguradora" ], receivers: [ "COMEX" ], description: "Poliza requerida cuando el incoterm es CIF.", state: "Contratada manualmente cuando aplica.", risk: "Queda NULL cuando no aplica.", key_data: "Poliza, valor asegurado, cobertura, aseguradora, vigencia, factura, embarque." },
    { phase: "post_zarpe_cobro", step: 22, code: "bill_of_lading", name: "Draft BL -> BL 3/3 Original", timeline: "T+1 / T+3", type: "derivado", category: "documento", obligation: "obligatorio", criticality: "critico", grain: "embarque", generators: [ "Forwarder" ], receivers: [ "COMEX" ], description: "Titulo de la mercancia; draft para revision y final negociable.", state: "Forwarder manda draft por email.", risk: "Revision manual y amendments costosos.", key_data: "BL, shipper/consignee/notify, HS, cantidades, pesos, contenedor/sello, buque/viaje, POL/POD, flete, originales." },
    { phase: "post_zarpe_cobro", step: 23, code: "documentary_set", name: "Set Documentario Completo -> Banco", timeline: "T+3", type: "derivado", category: "set", obligation: "obligatorio", criticality: "critico", grain: "set_documentario", generators: [ "COMEX" ], receivers: [ "Banco Local" ], description: "Set de documentos para cobro via SWIFT.", state: "Manual y sin validacion cruzada.", risk: "Banco rechaza inconsistencias internas.", key_data: "Checklist BL, Invoice, Packing List, COO, Phyto, CoA, seguro/fumigacion, SWIFT, banco, monto." },
    { phase: "post_zarpe_cobro", step: 24, code: "payment_reconciliation", name: "Payment + Reconciliacion", timeline: "T+18 / T+60", type: "externo", category: "artefacto", obligation: "recomendado", criticality: "alto", grain: "embarque", generators: [ "Banco Destino" ], receivers: [ "Export Manager" ], description: "Fondos recibidos y conciliacion contra factura.", state: "Monitoreo manual del extracto bancario.", risk: "Fees o FX distintos se detectan tarde.", key_data: "Monto recibido, fecha valor, banco, SWIFT, fees, tipo cambio, factura." },
  ].freeze

  FIELDS = [
    [ "shipper_name", "Nombre exacto del shipper", "string" ],
    [ "consignee", "Consignee", "string" ],
    [ "notify_party", "Notify party", "string" ],
    [ "hs_code", "HS code", "identifier" ],
    [ "product_description", "Descripcion de producto", "text" ],
    [ "lot_number", "Numero de lote", "identifier" ],
    [ "net_weight", "Peso neto", "weight" ],
    [ "gross_weight", "Peso bruto", "weight" ],
    [ "package_count", "Bultos / cajas / pallets", "number" ],
    [ "container_number", "Numero de contenedor", "identifier" ],
    [ "seal_number", "Numero de sello", "identifier" ],
    [ "pol", "Puerto origen", "string" ],
    [ "pod", "Puerto destino", "string" ],
    [ "incoterm", "Incoterm", "string" ],
    [ "invoice_amount", "Monto a cobrar", "money" ],
    [ "customer_legal_name", "Razon social cliente", "string" ],
    [ "vendor_legal_name", "Razon social proveedor", "string" ],
    [ "contract_effective_date", "Inicio contrato", "date" ],
    [ "contract_expiration_date", "Termino contrato", "date" ],
    [ "schedule_effective_date", "Inicio schedule", "date" ],
    [ "schedule_expiration_date", "Termino schedule", "date" ],
    [ "payment_terms", "Terminos de pago", "string" ],
    [ "delivery_terms", "Terminos de entrega", "text" ],
    [ "lead_time_days", "Lead time dias", "number" ],
    [ "first_delivery_date", "Primera entrega", "date" ],
    [ "service_level_commitment", "Compromiso de servicio", "string" ],
    [ "recall_contacts", "Contactos recall", "text" ],
    [ "compliance_requirements", "Requisitos cumplimiento", "text" ],
    [ "unit_price", "Precio unitario", "money" ],
    [ "case_pack", "Case pack", "number" ],
    [ "uom", "Unidad comercial", "string" ],
    [ "delivery_locations", "Ubicaciones de entrega", "text" ],
    [ "specifications_reference", "Referencia especificaciones", "text" ],
    [ "pallet_requirements", "Requisitos pallet", "text" ],
    [ "unsaleables_terms", "Terminos unsaleables", "text" ],
  ].freeze

  TEMPLATE_FIELDS = {
    "master_agreement" => %w[shipper_name customer_legal_name vendor_legal_name contract_effective_date contract_expiration_date payment_terms delivery_terms lead_time_days service_level_commitment recall_contacts compliance_requirements delivery_locations specifications_reference pallet_requirements unsaleables_terms hs_code incoterm],
    "purchase_order" => %w[consignee notify_party incoterm package_count invoice_amount product_description payment_terms delivery_terms lead_time_days],
    "product_spec" => %w[hs_code product_description net_weight unit_price case_pack uom specifications_reference],
    "certificate_of_analysis" => %w[lot_number product_description],
    "booking_confirmation" => %w[container_number pol pod],
    "shipping_instruction" => %w[shipper_name consignee notify_party hs_code product_description net_weight gross_weight package_count container_number pol pod incoterm delivery_terms lead_time_days delivery_locations],
    "container_loading_vgm" => %w[gross_weight container_number seal_number package_count],
    "dispatch_guide" => %w[lot_number net_weight package_count product_description],
    "phytosanitary_certificate" => %w[shipper_name consignee hs_code product_description lot_number],
    "commercial_invoice" => %w[shipper_name consignee hs_code product_description package_count net_weight incoterm invoice_amount payment_terms unit_price],
    "packing_list" => %w[package_count net_weight gross_weight container_number seal_number product_description case_pack uom],
    "certificate_of_origin" => %w[shipper_name consignee hs_code product_description invoice_amount],
    "bl_matrix" => %w[shipper_name consignee notify_party hs_code product_description package_count net_weight gross_weight container_number seal_number pol pod incoterm delivery_terms],
    "dus" => %w[hs_code package_count net_weight gross_weight incoterm invoice_amount],
    "marine_insurance" => %w[invoice_amount],
    "bill_of_lading" => %w[shipper_name consignee notify_party hs_code product_description package_count net_weight gross_weight container_number seal_number pol pod incoterm],
    "documentary_set" => %w[shipper_name consignee invoice_amount payment_terms],
    "payment_reconciliation" => %w[invoice_amount payment_terms],
  }.freeze

  DEPENDENCIES = [
    %w[master_agreement purchase_order], %w[master_agreement product_spec], %w[purchase_order product_spec],
    %w[purchase_order production_program_entry], %w[product_spec production_program_entry],
    %w[purchase_order lot_assignment], %w[product_spec lot_assignment],
    %w[purchase_order work_order], %w[product_spec work_order], %w[lot_assignment work_order],
    %w[work_order production_date_confirmation],
    %w[lot_assignment certificate_of_analysis], %w[product_spec certificate_of_analysis],
    %w[certificate_of_analysis positive_release],
    %w[purchase_order freight_quote], %w[production_date_confirmation booking_confirmation],
    %w[positive_release booking_confirmation], %w[freight_quote booking_confirmation],
    %w[booking_confirmation shipping_instruction], %w[purchase_order shipping_instruction], %w[product_spec shipping_instruction],
    %w[certificate_of_analysis shipping_instruction], %w[positive_release shipping_instruction],
    %w[shipping_instruction land_transport_coordination],
    %w[booking_confirmation container_loading_vgm], %w[work_order container_loading_vgm],
    %w[work_order dispatch_guide], %w[container_loading_vgm dispatch_guide],
    %w[booking_confirmation fumigation_certificate],
    %w[shipping_instruction phytosanitary_certificate], %w[fumigation_certificate phytosanitary_certificate],
    %w[purchase_order commercial_invoice], %w[booking_confirmation commercial_invoice], %w[container_loading_vgm commercial_invoice],
    %w[container_loading_vgm packing_list], %w[dispatch_guide packing_list],
    %w[shipping_instruction certificate_of_origin], %w[commercial_invoice certificate_of_origin],
    %w[shipping_instruction bl_matrix], %w[dispatch_guide bl_matrix],
    %w[shipping_instruction dus], %w[commercial_invoice dus], %w[phytosanitary_certificate dus],
    %w[purchase_order marine_insurance], %w[commercial_invoice marine_insurance],
    %w[bl_matrix bill_of_lading], %w[dus bill_of_lading], %w[container_loading_vgm bill_of_lading],
    %w[dispatch_guide bill_of_lading], %w[shipping_instruction bill_of_lading],
    %w[bill_of_lading documentary_set], %w[commercial_invoice documentary_set], %w[packing_list documentary_set],
    %w[certificate_of_origin documentary_set], %w[phytosanitary_certificate documentary_set],
    %w[certificate_of_analysis documentary_set], %w[marine_insurance documentary_set], %w[fumigation_certificate documentary_set],
    %w[documentary_set payment_reconciliation], %w[commercial_invoice payment_reconciliation],
  ].freeze

  SOURCE_OF_TRUTH_RULES = [
    { field: "package_count", authority: "purchase_order", targets: %w[dispatch_guide packing_list bill_of_lading], logic: "El comprador define las cantidades compradas; documentos derivados deben cuadrar.", failure: "correct_derivative" },
    { field: "invoice_amount", authority: "purchase_order", targets: %w[commercial_invoice], logic: "La factura debe reflejar el precio acordado en el PO salvo ajuste acordado.", failure: "correct_derivative" },
    { field: "shipper_name", authority: "master_agreement", targets: %w[bill_of_lading commercial_invoice certificate_of_origin phytosanitary_certificate documentary_set], logic: "El nombre legal exacto nace en el contrato marco.", failure: "correct_derivative" },
    { field: "consignee", authority: "purchase_order", targets: %w[shipping_instruction bl_matrix bill_of_lading commercial_invoice certificate_of_origin phytosanitary_certificate documentary_set], logic: "El comprador define quien recibe la carga.", failure: "correct_derivative" },
    { field: "incoterm", authority: "purchase_order", targets: %w[shipping_instruction commercial_invoice dus bill_of_lading], logic: "El incoterm impacta flete, seguro y valor declarado.", failure: "correct_derivative" },
    { field: "hs_code", authority: "product_spec", targets: %w[shipping_instruction bill_of_lading phytosanitary_certificate certificate_of_origin dus commercial_invoice], logic: "La descripcion y HS derivan de la especificacion del producto.", failure: "correct_derivative" },
    { field: "gross_weight", authority: "container_loading_vgm", targets: %w[packing_list bill_of_lading dus], logic: "El VGM es el peso bruto verificado por bascula certificada.", failure: "correct_derivative" },
    { field: "net_weight", authority: "dispatch_guide", targets: %w[shipping_instruction packing_list commercial_invoice bill_of_lading dus], logic: "La guia certifica el peso neto que salio fisicamente.", failure: "correct_derivative" },
    { field: "lot_number", authority: "dispatch_guide", targets: %w[certificate_of_analysis phytosanitary_certificate], logic: "La guia certifica que lote salio fisicamente de planta.", failure: "correct_derivative" },
    { field: "container_number", authority: "booking_confirmation", targets: %w[bl_matrix bill_of_lading packing_list], logic: "El booking asigna el contenedor; planta confirma sello/carga.", failure: "correct_derivative" },
    { field: "invoice_amount", authority: "commercial_invoice", targets: %w[payment_reconciliation documentary_set], logic: "La invoice es la verdad financiera del cobro.", failure: "reconcile_exception" },
    { field: "payment_terms", authority: "master_agreement", targets: %w[commercial_invoice documentary_set payment_reconciliation], logic: "Los terminos de pago confirmados en el contrato y schedule rigen cobranza y set documentario.", failure: "correct_derivative" },
    { field: "delivery_terms", authority: "master_agreement", targets: %w[shipping_instruction bl_matrix bill_of_lading], logic: "Las condiciones de entrega confirmadas en el contrato deben fluir a instrucciones y documentos de transporte.", failure: "correct_derivative" },
    { field: "delivery_locations", authority: "master_agreement", targets: %w[shipping_instruction], logic: "Las ubicaciones designadas por el cliente condicionan instrucciones logisticas aguas abajo.", failure: "correct_derivative" },
  ].freeze

  def self.call(organization)
    new(organization).call
  end

  def initialize(organization)
    @organization = organization
  end

  def call
    ActsAsTenant.with_tenant(organization) do
      seed_phases
      seed_documents
      seed_fields
      seed_template_fields
      seed_dependencies
      seed_source_of_truth_rules
    end
  end

  private

    attr_reader :organization

    def seed_phases
      PHASES.each do |attrs|
        phase = organization.workflow_phases.find_or_initialize_by(code: attrs[:code])
        phase.update!(attrs)
      end
    end

    def seed_documents
      DOCUMENTS.each do |attrs|
        phase = organization.workflow_phases.find_by!(code: attrs.fetch(:phase))
        document = organization.document_templates.find_or_initialize_by(code: attrs[:code])
        document.update!(
          workflow_phase: phase,
          step_number: attrs[:step],
          name: attrs[:name],
          timeline: attrs[:timeline],
          document_type: attrs[:type],
          category: attrs[:category],
          obligation: attrs[:obligation],
          criticality: attrs[:criticality],
          grain: attrs[:grain],
          destinations: attrs[:destinations] || [],
          generator_roles: attrs[:generators] || [],
          receiver_roles: attrs[:receivers] || [],
          description: attrs[:description],
          current_state: attrs[:state],
          as_is_risk: attrs[:risk],
          source_of_truth_fields: attrs[:sot],
          key_data: attrs[:key_data],
          active: true
        )
      end
    end

    def seed_fields
      FIELDS.each do |key, name, value_type|
        field = organization.document_field_definitions.find_or_initialize_by(key: key)
        field.update!(name: name, value_type: value_type)
      end
    end

    def seed_template_fields
      TEMPLATE_FIELDS.each do |document_code, field_keys|
        document = organization.document_templates.find_by!(code: document_code)
        field_keys.each do |field_key|
          field = organization.document_field_definitions.find_by!(key: field_key)
          template_field = organization.document_template_fields.find_or_initialize_by(
            document_template: document,
            document_field_definition: field
          )
          template_field.update!(requirement: "required")
        end
      end
    end

    def seed_dependencies
      DEPENDENCIES.each do |prerequisite_code, dependent_code|
        prerequisite = organization.document_templates.find_by!(code: prerequisite_code)
        dependent = organization.document_templates.find_by!(code: dependent_code)
        dependency = organization.document_template_dependencies.find_or_initialize_by(
          prerequisite_document_template: prerequisite,
          dependent_document_template: dependent
        )
        dependency.update!(condition: nil)
      end
    end

    def seed_source_of_truth_rules
      SOURCE_OF_TRUTH_RULES.each do |attrs|
        field = organization.document_field_definitions.find_by!(key: attrs[:field])
        authority = organization.document_templates.find_by!(code: attrs[:authority])
        rule = organization.source_of_truth_rules.find_or_initialize_by(
          document_field_definition: field,
          authoritative_document_template: authority
        )
        rule.update!(logic: attrs[:logic], failure_action: attrs[:failure])

        attrs[:targets].each do |target_code|
          target = organization.document_templates.find_by!(code: target_code)
          organization.source_of_truth_rule_targets.find_or_create_by!(
            source_of_truth_rule: rule,
            document_template: target
          )
        end
      end
    end
end
