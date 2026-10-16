using System.Globalization;
using System.Text.RegularExpressions;

namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Correio da Resenha: quem está na foto fica de fora e a turma escreve um
/// bilhete curto sobre a pessoa. Anônimo de verdade: os bilhetes saem
/// embaralhados e sem autor, nem quem criou a sala sabe quem escreveu.
/// </summary>
public sealed partial class Sala
{
    /// <summary>Bilhete, não textão.</summary>
    internal const int TamanhoDoBilhete = 20;

    /// <summary>Quem está na foto marca (ou desmarca) o bilhete de que mais gostou.</summary>
    public void EscolherFavorito(string token, int numeroDaRodada, int indice)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada) || Fase != FaseDaSala.Revelada) return;
            var rodada = Rodada!;
            if (rodada.Carta.Modo != ModoDeJogo.Correio)
                throw new AcaoNaoPermitidaException("Só vale no Correio da Resenha.");
            if (jogador.Id != rodada.Alvo)
                throw new AcaoNaoPermitidaException("Quem escolhe o favorito é quem está na foto.");
            if (indice < 0 || indice >= rodada.Revelacao!.Bilhetes.Count)
                throw new AcaoNaoPermitidaException("Esse bilhete não existe.");
            rodada.Favorito = rodada.Favorito == indice ? null : indice;
            Tocar();
        }
    }

    private static string ValidarBilhete(Rodada rodada, Jogador jogador, string resposta)
    {
        if (jogador.Id == rodada.Alvo)
            throw new AcaoNaoPermitidaException("Essa é sobre você: aguarde a turma escrever.");
        var bilhete = Regex.Replace(resposta ?? string.Empty, @"\s+", " ").Trim();
        if (bilhete.Length == 0)
            throw new AcaoNaoPermitidaException("Escreva o bilhete.");
        // Emoji conta como uma letra: é o que a pessoa vê na tela.
        if (new StringInfo(bilhete).LengthInTextElements > TamanhoDoBilhete)
            throw new AcaoNaoPermitidaException($"Bilhete curto: até {TamanhoDoBilhete} letras.");
        return bilhete;
    }

    /// <summary>Ninguém bebe: a graça é ler. Embaralha para a ordem não entregar ninguém.</summary>
    private Revelacao RevelarBilhetes(Rodada rodada, List<KeyValuePair<Guid, string>> respostas) =>
        new([], [], [], [], null)
        {
            Escolhidos = rodada.Alvo is { } alvo && _jogadores.Any(j => j.Id == alvo) ? [alvo] : [],
            Bilhetes = respostas.Select(r => r.Value).OrderBy(_ => _sorteio.Next()).ToList()
        };
}
