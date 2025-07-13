pacman::p_load(RCurl,
tidyverse,
read.dbc)

# SIASUS PA ####
## Lista arquivos ####

# A URL deve terminar com uma barra "/" para indicar que queremos a listagem do diretório
url <- "ftp://ftp.datasus.gov.br/dissemin/publicos/SIASUS/200801_/Dados/"
# O Rcurl retorna a listagem como um único texto longo, com cada arquivo em uma nova linha.
listagem_crua <- getURL(url, ftp.use.epsv = FALSE, dirlistonly = FALSE)
# Dividimos o texto longo em linhas individuais
linhas <- unlist(strsplit(listagem_crua, "\r?\n"))
# Removemos linhas em branco que possam ter sido criadas na divisão
linhas <- linhas[linhas != ""]

# A maneira mais robusta de ler esses dados é usar read.table,
# que consegue lidar com os múltiplos espaços entre as colunas.
# Usamos textConnection para que read.table leia nosso vetor de linhas como se fosse um arquivo.
df_ftp <- read.table(textConnection(linhas), stringsAsFactors = FALSE)

# 5. Limpar e renomear as colunas do data frame
colnames(df_ftp) <- c("dia", "hora", "tamanho", "nome")


df_info_arquivos <- df_ftp 
## Filtra e baixa ####

arquivos_para_baixar <- df_info_arquivos |> 
  mutate(ano_mes = as.numeric(str_extract(nome, "[0-9]{4}"))) |> 
  filter(str_detect(nome, '^PA'),
                    ano_mes >= 2001 & ano_mes <= 2512)
  

# 2. Criar uma pasta para salvar os arquivos (se ela não existir)
pasta_destino <- "h:/dados_siasus" # Nome da pasta onde os arquivos serão salvos
if (!dir.exists(pasta_destino)) {
  dir.create(pasta_destino)
  cat("Pasta '", pasta_destino, "' criada com sucesso.\n")
}


for (i in 1:nrow(arquivos_para_baixar)) {
  
  # Pega o nome do arquivo da linha atual do data frame
  nome_do_arquivo <- arquivos_para_baixar$nome[i]
  
  # Monta a URL completa para o arquivo
  url_completa_arquivo <- paste0(url, nome_do_arquivo)
  
  # Monta o caminho completo de destino (pasta + nome do arquivo)
  caminho_destino <- file.path(pasta_destino, nome_do_arquivo)
  
  # Informa ao usuário qual arquivo está sendo baixado
  cat("Baixando:", nome_do_arquivo, "-> para:", caminho_destino, "\n")
  
  # Faz o download do arquivo
  # 'mode = "wb"' é crucial para baixar arquivos binários como .dbc corretamente
  tryCatch({
    download.file(url_completa_arquivo, destfile = caminho_destino, mode = "wb", quiet = TRUE)
    cat("  -> Download de", nome_do_arquivo, "concluído.\n")
  }, error = function(e) {
    cat("  -> ERRO ao baixar", nome_do_arquivo, ":", e$message, "\n")
  })
}

cat("\nProcesso de download finalizado.\n")
