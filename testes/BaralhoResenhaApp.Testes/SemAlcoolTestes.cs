using System.Text.RegularExpressions;
using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// 🧃 Sala sem álcool: o cofrinho continua, mas quando enche sai uma prenda
/// (um desafio rápido) no lugar do gole. As cartas que falam de bebida não saem.
/// </summary>
public sealed class SemAlcoolTestes
{
    private static readonly Prendas Banco = new(
        Leve: ["Fale com sotaque até a próxima carta.", "Imite alguém da mesa."],
        Resenha: ["Mostre a última foto da galeria."],
        Picante: ["Conte o seu crush de escola."],
        Micos: ["Cante o hino do seu time.", "Dance sem música por 20 segundos.", "Declame um poema para a mesa."]);

    private static ConfiguracaoDoJogo SemAlcool(ModoDeJogo modo, NivelDaCarta nivel = NivelDaCarta.Leve) =>
        new(nivel, [modo], true, Ritmo: RitmoDaBebida.Raiz, SemAlcool: true);

    private static (Sala Sala, Jogador Ana, Jogador Bia) Mesa(
        IReadOnlyList<Carta> cartas, ConfiguracaoDoJogo configuracao, bool biaSemAlcool = false)
    {
        var sala = new Sala("ABCD", new Baralho(cartas, prendas: Banco), new Random(1));
        var ana = sala.Entrar("Ana", false);
        var bia = sala.Entrar("Bia", biaSemAlcool);
        sala.Configurar(ana.Token, configuracao);
        sala.Comecar(ana.Token);
        return (sala, ana, bia);
    }

    private static readonly Carta Oculos = new("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Pega quem usa óculos.");

    [Fact]
    public void OPadraoEhComAlcool()
    {
        Assert.False(ConfiguracaoDoJogo.Padrao.SemAlcool);
    }

    [Fact]
    public void QuandoOCofrinhoEncheSaiUmaPrendaNoLugarDoGole()
    {
        var (sala, ana, bia) = Mesa([Oculos], SemAlcool(ModoDeJogo.BebaSe));

        sala.AlternarBebi(bia.Token, sala.Rodada!.Numero);

        var rodada = sala.Visao(ana.Token).Rodada!;
        Assert.Equal([bia.Id], rodada.BebemAgora);
        var prenda = Assert.Single(rodada.Prendas[bia.Id]);
        Assert.Contains(prenda, Banco.Leve);
        // A prenda é a mesma em todas as consultas: ninguém troca a sua na sorte.
        Assert.Equal(prenda, Assert.Single(sala.Visao(bia.Token).Rodada!.Prendas[bia.Id]));
    }

    [Fact]
    public void ComAlcoolNinguemPagaPrenda()
    {
        var (sala, ana, bia) = Mesa([Oculos], SemAlcool(ModoDeJogo.BebaSe) with { SemAlcool = false });

        sala.AlternarBebi(bia.Token, sala.Rodada!.Numero);

        Assert.Equal([bia.Id], sala.Visao(ana.Token).Rodada!.BebemAgora);
        Assert.Empty(sala.Visao(ana.Token).Rodada!.Prendas);
    }

    [Fact]
    public void QuemEntrouSemAlcoolTambemPagaPrendaNaSalaSemAlcool()
    {
        var (sala, ana, bia) = Mesa([Oculos], SemAlcool(ModoDeJogo.BebaSe), biaSemAlcool: true);

        sala.AlternarBebi(bia.Token, sala.Rodada!.Numero);

        var visao = sala.Visao(ana.Token);
        Assert.Equal(1, bia.Goles);
        Assert.Single(visao.Rodada!.Prendas[bia.Id]);
        // Na sala sem álcool ninguém é "o que não bebe": é todo mundo igual.
        Assert.False(visao.Jogadores.Single(j => j.Id == bia.Id).SemAlcool);
    }

    [Fact]
    public void ADosePagaUmaPrendaPorGole()
    {
        var mico = new Carta("bs-2", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "{jogador} conta um mico ou paga 2.", Goles: 2);
        var (sala, ana, bia) = Mesa([mico], SemAlcool(ModoDeJogo.BebaSe));

        sala.AlternarBebi(bia.Token, sala.Rodada!.Numero);

        var prendas = sala.Visao(ana.Token).Rodada!.Prendas[bia.Id];
        Assert.Equal(2, prendas.Count);
        Assert.Equal(2, prendas.Distinct().Count());
    }

    [Fact]
    public void APrendaSegueONivelDaNoite()
    {
        var picante = new Carta("bs-3", ModoDeJogo.BebaSe, NivelDaCarta.Picante, "Pega quem já mandou nude.");
        var (sala, ana, bia) = Mesa([picante], SemAlcool(ModoDeJogo.BebaSe, NivelDaCarta.Picante));
        var vistas = new HashSet<string>();

        for (var i = 0; i < 12; i++)
        {
            sala.AlternarBebi(bia.Token, sala.Rodada!.Numero);
            vistas.UnionWith(sala.Visao(ana.Token).Rodada!.Prendas[bia.Id]);
            sala.Proxima(ana.Token, sala.Rodada.Numero);
        }

        // No Picante vale de tudo; o Leve nunca vê prenda de nível acima.
        Assert.Superset(new HashSet<string>([.. Banco.Leve, .. Banco.Resenha, .. Banco.Picante]), vistas);
        Assert.Contains(Banco.Picante[0], vistas);
        var (leve, ana2, bia2) = Mesa([Oculos], SemAlcool(ModoDeJogo.BebaSe));
        for (var i = 0; i < 6; i++)
        {
            leve.AlternarBebi(bia2.Token, leve.Rodada!.Numero);
            Assert.Contains(Assert.Single(leve.Visao(ana2.Token).Rodada!.Prendas[bia2.Id]), Banco.Leve);
            leve.Proxima(ana2.Token, leve.Rodada.Numero);
        }
    }

    [Theory]
    [InlineData("Quem é mais provável de chorar depois de beber?")]
    [InlineData("Quem é mais provável de levar cerveja para a festa?")]
    [InlineData("Pedra, papel e tesoura valendo dose: {jogador} contra {jogador2}.")]
    [InlineData("Quantos ml tem uma garrafa de cachaça?")]
    public void CartaQueFalaDeBebidaNaoSaiNaSalaSemAlcool(string texto)
    {
        var bebida = new Carta("mp-1", ModoDeJogo.MaisProvavel, NivelDaCarta.Leve, texto);
        var outra = new Carta("mp-2", ModoDeJogo.MaisProvavel, NivelDaCarta.Leve, "Quem é mais provável de chegar atrasado?");
        var baralho = new Baralho([bebida, outra]);

        for (var i = 0; i < 20; i++)
            Assert.Equal("mp-2", baralho.Sortear(SemAlcool(ModoDeJogo.MaisProvavel), new HashSet<string>(), 4, false, new Random(i))!.Id);
        Assert.Contains(Enumerable.Range(0, 20), i =>
            baralho.Sortear(SemAlcool(ModoDeJogo.MaisProvavel) with { SemAlcool = false }, new HashSet<string>(), 4, false, new Random(i))!.Id == "mp-1");
    }

    [Theory]
    [InlineData("Proibido falar \"tipo\". Escorregou, bebeu.", "Proibido falar \"tipo\". Escorregou, leva ponto.")]
    [InlineData("Quem falar palavrão bebe.", "Quem falar palavrão leva ponto.")]
    [InlineData("Quem rir de piada ruim bebe. Quem não rir também.", "Quem rir de piada ruim leva ponto. Quem não rir também.")]
    public void NaRegraQuemVacilaLevaPontoEmVezDeBeber(string texto, string semAlcool)
    {
        var regra = new Carta("rr-1", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve, texto);
        var (sala, _, _) = Mesa([regra], SemAlcool(ModoDeJogo.RegraRelampago));

        Assert.Equal(semAlcool, sala.Rodada!.Texto);
        Assert.Equal(semAlcool, sala.Regra!.Texto);
    }

    [Fact]
    public void QuemAcertaODistribuiUmaPrendaNoLugarDosGoles()
    {
        var degraus = new Carta("ch-1", ModoDeJogo.ChutaAi, NivelDaCarta.Leve, "Quantos degraus tem o Cristo?", Resposta: 220);
        var (sala, ana, bia) = Mesa([degraus], SemAlcool(ModoDeJogo.ChutaAi));

        sala.Responder(ana.Token, sala.Rodada!.Numero, "200");
        sala.Responder(bia.Token, sala.Rodada.Numero, "1000");

        var rodada = sala.Visao(bia.Token).Rodada!;
        Assert.Equal([ana.Id], rodada.Revelacao!.Escolhidos);
        Assert.Contains(rodada.PrendaParaDar, Banco.Leve);
        Assert.Equal(rodada.PrendaParaDar, sala.Visao(ana.Token).Rodada!.PrendaParaDar);
    }

    [Fact]
    public void ComAlcoolQuemAcertaDistribuiGolesSemPrenda()
    {
        var degraus = new Carta("ch-1", ModoDeJogo.ChutaAi, NivelDaCarta.Leve, "Quantos degraus tem o Cristo?", Resposta: 220);
        var (sala, ana, bia) = Mesa([degraus], SemAlcool(ModoDeJogo.ChutaAi) with { SemAlcool = false });

        sala.Responder(ana.Token, sala.Rodada!.Numero, "200");
        sala.Responder(bia.Token, sala.Rodada.Numero, "1000");

        Assert.Null(sala.Visao(bia.Token).Rodada!.PrendaParaDar);
    }

    [Fact]
    public void OBancoDePrendasTemDeTudoENadaDeBebida()
    {
        var prendas = CatalogoDeCartas.Carregar().Prendas;

        Assert.True(prendas.Leve.Count >= 25, $"Leve: {prendas.Leve.Count}");
        Assert.True(prendas.Resenha.Count >= 15, $"Resenha: {prendas.Resenha.Count}");
        Assert.True(prendas.Picante.Count >= 8, $"Picante: {prendas.Picante.Count}");
        Assert.True(prendas.Micos.Count >= 12, $"Micos: {prendas.Micos.Count}");
        string[] todas = [.. prendas.Leve, .. prendas.Resenha, .. prendas.Picante, .. prendas.Micos];
        Assert.Equal(todas.Length, todas.Distinct().Count());
        Assert.DoesNotContain(todas, p => Regex.IsMatch(p, @"beb|gole|cerveja|dose|álcool", RegexOptions.IgnoreCase));
    }

    [Fact]
    public void NoFimOPlacarContaPrendasEmVezDeGoles()
    {
        var (sala, ana, bia) = Mesa([Oculos], SemAlcool(ModoDeJogo.BebaSe));
        sala.AlternarBebi(bia.Token, sala.Rodada!.Numero);

        sala.Encerrar(ana.Token);

        var visao = sala.Visao(ana.Token);
        var rei = visao.Premios!.Single(p => p.Jogadores.Contains(bia.Id) && p.Titulo == "Rei(nha) da noite");
        Assert.Equal("🎟️", rei.Emoji);
        Assert.Equal("1 ponto · 1 prenda", rei.Descricao);
        Assert.Equal(1, visao.Resumo!.Goles);
    }
}
