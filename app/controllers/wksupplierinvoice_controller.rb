class WksupplierinvoiceController < WksupplierorderentityController
  unloadable

	@@simutex = Mutex.new

	def newSupOrderEntity(parentId, parentType)
		super			
		@poId =params[:po_id].to_i
		if !params[:populate_items].blank? && params[:populate_items] == '1'
			@invoiceItem = WkInvoiceItem.where(:invoice_id => params[:po_id].to_i).select(:name, :rate, :amount, :quantity, :item_type, :currency, :project_id, :modifier_id,  :invoice_id )
		end 
	end
	
	def editOrderEntity
		super
		unless params[:invoice_id].blank?
			@siObj = WkPoSupplierInvoice.find(@invoice.sup_inv_po.id) unless @invoice.blank?
		end
	end
	
	def saveOrderInvoice(parentId, parentType,  projectId, invDate,  invoicePeriod, isgenerate, getInvoiceType)
		begin			
			@@simutex.synchronize do
				addInvoice(parentId, parentType,  projectId, invDate,  invoicePeriod, isgenerate, getInvoiceType)
			end				
		rescue => ex
		  logger.error ex.message
		end
	end
	
	def saveOrderRelations
		savePoSupInv(params[:si_id], params[:si_inv_id], @invoice.id)
	end
	
	def getRfqPoIds
		quoteIds = ""	
		rfqObj = ""
		rfqObj = WkInvoice.where(:id => getInvoiceIds(params[:rfq_id].to_i, 'PO', false), :parent_id => params[:parent_id].to_i, :parent_type => params[:parent_type]).order(:id)
		
		rfqObj.each do | entry|
			quoteIds <<  entry.id.to_s() + ',' + entry.id.to_s()  + "\n" 
		end
		respond_to do |format|
			format.text  { render :text => quoteIds }
		end
	end

  
	def getInvoiceType
		'SI'
	end
	
	def getHeaderLabel
		l(:label_supplier_invoice)
	end
	
	def getLabelNewInv
		l(:label_new_sup_invoice)
	end
		
	def getPopulateChkBox
		l(:label_populate_purchase_items)
	end
	
	def getItemLabel
		l(:label_si_items)
	end
	
	def getLabelInvNum
		l(:label_sp_number)
	end
	
	def getDateLbl
		l(:label_sp_date)
	end
	
	def getAdditionalDD
		"wksupplierinvoice/siadditionaldd"
	end
	
	def editInvNumber
		true
	end
	
	def getOrderNumberPrefix
		'wktime_si_no_prefix'
	end
	
	def getNewHeaderLbl
		l(:label_new_sup_invoice)
	end
	
end
